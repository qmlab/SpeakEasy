//
//  CameraService.swift
//  SpeakEasy
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
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var lastProcessingTime = Date()
    private let processingInterval: TimeInterval = 1.0
    
    private lazy var classificationRequest: VNCoreMLRequest? = {
        do {
            let config = MLModelConfiguration()
            let model = try VNCoreMLModel(for: MobileNetV2(configuration: config).model)
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            print("Failed to load ML model: \(error)")
            return nil
        }
    }()
    
    override init() {
        super.init()
        checkPermission()
    }
    
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
    
    func setupCamera() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
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
    
    func startSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    func classifyImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        isProcessing = true
        capturedImage = image
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let request = self?.classificationRequest else {
                DispatchQueue.main.async {
                    self?.isProcessing = false
                }
                return
            }
            
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
    
    private func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isProcessing = false
            
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                self?.recognizedObject = nil
                self?.confidence = 0
                return
            }
            
            let label = topResult.identifier
                .components(separatedBy: ",")
                .first?
                .trimmingCharacters(in: .whitespaces)
                .capitalized ?? topResult.identifier
            
            self?.recognizedObject = label
            self?.confidence = topResult.confidence
        }
    }
    
    func mapToKnownObject(_ recognizedLabel: String) -> ObjectItem? {
        let lowercased = recognizedLabel.lowercased()
        
        return ObjectData.allObjects.first { object in
            let objectName = object.name.lowercased()
            return lowercased.contains(objectName) || objectName.contains(lowercased)
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessingTime) >= processingInterval else { return }
        lastProcessingTime = currentTime
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = classificationRequest else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform classification: \(error)")
        }
    }
}
