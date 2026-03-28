//
//  CameraService.swift
//  RisingStarKid
//
//  Live camera preview + real-time object detection using Vision framework.
//  Uses YOLOv3 CoreML model for per-object bounding box detection with labels.
//  Supports target label matching for adaptive learning object cognition tasks.
//

import Foundation
import AVFoundation
import Vision
import SwiftUI
import CoreML

/// A single detected object with its label, confidence, and bounding box
struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    /// Bounding box in Vision coordinates (origin bottom-left, normalized 0…1)
    let boundingBox: CGRect
}

class CameraService: NSObject, ObservableObject {
    @Published var recognizedObject: String?
    @Published var confidence: Float = 0
    @Published var isProcessing = false
    @Published var permissionGranted = false
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false

    /// Top N classification results for display / matching (whole-image)
    @Published var topClassifications: [(label: String, confidence: Float)] = []

    /// Per-object detections with bounding boxes (from YOLO)
    @Published var detectedObjects: [DetectedObject] = []

    /// When set, `matchFound` fires when any detection contains this label
    @Published var targetLabel: String?
    @Published var matchFound = false
    @Published var matchConfidence: Float = 0

    /// Exposed for SwiftUI live preview via CameraPreviewView
    @Published private(set) var captureSession: AVCaptureSession?

    /// Internal session reference accessible from sessionQueue (avoids main-thread-only @Published)
    private var _session: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var lastProcessingTime = Date()
    private let processingInterval: TimeInterval = 0.5  // 2 FPS for real-time feel

    /// YOLO object detection request (lazy-loaded from CoreML model)
    private lazy var objectDetectionRequest: VNCoreMLRequest? = {
        guard let model = try? YOLOv3Int8LUT(configuration: MLModelConfiguration()).model,
              let visionModel = try? VNCoreMLModel(for: model) else {
            print("Failed to load YOLOv3 model, falling back to classification")
            return nil
        }
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            self?.processDetections(for: request, error: error)
        }
        request.imageCropAndScaleOption = .scaleFill
        return request
    }()

    /// Fallback whole-image classification (used when YOLO unavailable)
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
        guard _session == nil else { return }
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

        _session = session
        videoOutput = output
        // Publish on main thread so SwiftUI re-renders CameraPreviewView
        DispatchQueue.main.async {
            self.captureSession = session
        }
    }

    // MARK: - Session Control

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self._session == nil {
                self.configureSession()
            }
            self._session?.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?._session?.stopRunning()
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
            self.detectedObjects = []
        }
    }

    // MARK: - Static Image Classification

    func classifyImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        DispatchQueue.main.async { self.isProcessing = true }
        capturedImage = image

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                if let detectionReq = self.objectDetectionRequest {
                    try handler.perform([detectionReq])
                } else {
                    try handler.perform([self.classificationRequest])
                }
            } catch {
                print("Failed to perform detection: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }

    // MARK: - YOLO Object Detection Processing

    private func processDetections(for request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            DispatchQueue.main.async { [weak self] in
                self?.isProcessing = false
                self?.detectedObjects = []
                self?.recognizedObject = nil
                self?.confidence = 0
            }
            return
        }

        // Filter detections above 30% confidence and take top 10
        let objects = results
            .filter { $0.confidence > 0.30 }
            .prefix(10)
            .map { observation -> DetectedObject in
                let topLabel = observation.labels.first
                let label = topLabel?.identifier.capitalized ?? "Unknown"
                let conf = topLabel?.confidence ?? observation.confidence
                return DetectedObject(
                    label: label,
                    confidence: conf,
                    boundingBox: observation.boundingBox
                )
            }

        let topObject = objects.first

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isProcessing = false
            self.detectedObjects = Array(objects)
            self.recognizedObject = topObject?.label
            self.confidence = topObject?.confidence ?? 0
            self.topClassifications = objects.map { ($0.label, $0.confidence) }

            // Check target match
            if let target = self.targetLabel {
                let matched = objects.first { obj in
                    obj.label.lowercased().contains(target) ||
                    target.contains(obj.label.lowercased())
                }
                if let matched = matched {
                    self.matchFound = true
                    self.matchConfidence = matched.confidence
                }
            }
        }
    }

    // MARK: - Fallback Classification Processing

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

        do {
            if let detectionReq = objectDetectionRequest {
                try handler.perform([detectionReq])
            } else {
                try handler.perform([classificationRequest])
            }
        } catch {
            print("Failed to perform detection: \(error)")
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable

/// Custom UIView that auto-resizes its AVCaptureVideoPreviewLayer via layoutSubviews
class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    func setSession(_ session: AVCaptureSession) {
        guard previewLayer == nil else { return }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.addSublayer(layer)
        previewLayer = layer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer to show live camera feed
struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black

        if let session = cameraService.captureSession {
            view.setSession(session)
        }

        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // If session was set up after initial makeUIView, add the layer now
        if uiView.previewLayer == nil, let session = cameraService.captureSession {
            uiView.setSession(session)
        }
    }
}

// MARK: - Bounding Box Overlay

/// Converts Vision's normalized bounding box (origin bottom-left) to SwiftUI coordinates
struct BoundingBoxOverlay: View {
    let detectedObjects: [DetectedObject]
    let geometry: GeometryProxy

    var body: some View {
        ForEach(detectedObjects) { obj in
            let rect = visionRectToView(obj.boundingBox, in: geometry)
            ZStack(alignment: .topLeading) {
                // Bounding box
                RoundedRectangle(cornerRadius: 4)
                    .stroke(colorForLabel(obj.label), lineWidth: 2.5)
                    .frame(width: rect.width, height: rect.height)

                // Label tag
                HStack(spacing: 4) {
                    Text(obj.label)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("\(Int(obj.confidence * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .opacity(0.8)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(colorForLabel(obj.label).opacity(0.85))
                )
                .offset(y: -24)
            }
            .position(x: rect.midX, y: rect.midY)
        }
    }

    /// Convert Vision coordinates (bottom-left origin, 0…1) to view coordinates
    private func visionRectToView(_ rect: CGRect, in geo: GeometryProxy) -> CGRect {
        let w = geo.size.width
        let h = geo.size.height
        let x = rect.origin.x * w
        let y = (1 - rect.origin.y - rect.height) * h
        return CGRect(x: x, y: y, width: rect.width * w, height: rect.height * h)
    }

    /// Assign a consistent color per label
    private func colorForLabel(_ label: String) -> Color {
        let colors: [Color] = [.green, .blue, .orange, .purple, .pink, .cyan, .yellow, .red, .mint, .indigo]
        let hash = abs(label.hashValue % colors.count)
        return colors[hash % colors.count]
    }
}
