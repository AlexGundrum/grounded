//
//  RealTimeARManager.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import Foundation
import SwiftUI
import AVFoundation
import UIKit

// MARK: - Real-Time AR Manager
class RealTimeARManager: ObservableObject {
    @Published var detectedObjects: [ARObject] = []
    @Published var isProcessing = false
    @Published var lastUpdateTime: Date?
    
    private var updateTimer: Timer?
    var currentPhase: CrisisPhase = .computerVision
    private let updateInterval: TimeInterval = 5.0 // 5 second updates for AR phase
    private let serverIP = "100.66.12.253"
    private let serverPort = "2419"
    
    enum CrisisPhase {
        case computerVision  // Phase 1: CV scanning only
        case arMode          // Phase 2: AR visualization enabled
    }
    
    // Camera controller reference for real image capture
    weak var cameraController: ContinuousCameraViewController?
    
    // Performance tracking
    private var frameCount = 0
    private var successfulDetections = 0
    private var averageProcessingTime: TimeInterval = 0
    
    func startRealTimeDetection() {
        currentPhase = .arMode
        print("🎯 Starting real-time AR detection in AR mode")
        
        // Only start in AR mode - CV phase is handled by PingARManager
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.captureAndProcessFrame()
        }
    }
    
    func startRealTimeDetectionWithPhase(_ phase: CrisisPhase) {
        currentPhase = phase
        
        switch phase {
        case .computerVision:
            print("🚫 RealTimeARManager disabled during CV phase - PingARManager handles scanning")
            // Don't start timer during CV phase
            
        case .arMode:
            print("🎯 Starting real-time AR detection in AR mode")
            updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
                self?.captureAndProcessFrame()
            }
        }
    }
    
    func stopRealTimeDetection() {
        updateTimer?.invalidate()
        updateTimer = nil
        print("🛑 Real-time AR detection stopped")
    }
    
    private func captureAndProcessFrame() {
        guard !isProcessing else {
            print("⏳ Skipping frame - still processing previous")
            return
        }
        
        isProcessing = true
        frameCount += 1
        
        // Capture current camera frame
        captureCurrentFrame { [weak self] imageData in
            guard let imageData = imageData else {
                self?.isProcessing = false
                return
            }
            
            self?.sendFrameForProcessing(imageData)
        }
    }
    
    private func captureCurrentFrame(completion: @escaping (Data?) -> Void) {
        // Get the current camera frame from the existing camera system
        guard let cameraController = cameraController else {
            print("❌ No camera controller available for real-time AR")
            completion(nil)
            return
        }
        
        // Use real camera controller to capture actual image
        cameraController.captureImageForProcessing(completion: completion)
    }
    
    
    private func sendFrameForProcessing(_ imageData: Data) {
        let startTime = Date()
        let imageBase64 = imageData.base64EncodedString()
        
        let url = URL(string: "http://\(serverIP):\(serverPort)/upload_image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 2.0 // 2 second timeout for real-time
        
        let payload = [
            "image": imageBase64,
            "heart_rate": 75.0,  // Add required heart_rate field as Float
            "timestamp": Date().timeIntervalSince1970,
            "frame_id": frameCount,
            "request_type": "real_time_ar"
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("❌ Failed to serialize frame data: \(error)")
            isProcessing = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if let error = error {
                    print("❌ Frame processing error: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received from frame processing")
                    return
                }
                
                self?.processARResponse(data, processingTime: Date().timeIntervalSince(startTime))
            }
        }.resume()
    }
    
    private func processARResponse(_ data: Data, processingTime: TimeInterval) {
        do {
            let response = try JSONDecoder().decode(ARResponse.self, from: data)
            
            // Update performance metrics
            averageProcessingTime = (averageProcessingTime + processingTime) / 2
            successfulDetections += 1
            
            // Update detected objects with coordinates from anchor_backend
            if let arData = response.ar_data {
                detectedObjects = arData
                lastUpdateTime = Date()
                
                print("🎯 anchor_backend OpenCV detected \(arData.count) objects in \(String(format: "%.2f", processingTime))s")
                
                // Log detected objects with coordinates for debugging
                for object in arData {
                    print("  📍 \(object.label) at coordinates (x: \(String(format: "%.2f", object.box_x)), y: \(String(format: "%.2f", object.box_y)))")
                }
                
                // Phase-aware AR visualization
                if currentPhase == .arMode {
                    print("✨ AR PHASE: Real-time objects ready for 3D visualization")
                    // TODO: Trigger 3D AR visualization for real-time objects if needed
                    // This could integrate with the 3D ping system for automatic visualization
                } else {
                    print("📸 CV PHASE: Real-time objects detected but AR visualization disabled")
                }
            }
            
        } catch {
            print("❌ Failed to decode AR response: \(error)")
        }
    }
    
    // MARK: - Performance Monitoring
    
    func getPerformanceStats() -> (frameCount: Int, successRate: Double, avgProcessingTime: TimeInterval) {
        let successRate = frameCount > 0 ? Double(successfulDetections) / Double(frameCount) : 0
        return (frameCount, successRate, averageProcessingTime)
    }
    
    func resetStats() {
        frameCount = 0
        successfulDetections = 0
        averageProcessingTime = 0
    }
}

// MARK: - Enhanced AR Response Model
struct EnhancedARResponse: Decodable {
    let audioBase64: String?
    let responseText: String?
    let ar_data: [ARObject]?
    let processing_time: Double?
    let frame_id: Int?
    let confidence_scores: [Double]?
    
    // Computed properties
    var hasAudio: Bool {
        return audioBase64 != nil && !audioBase64!.isEmpty
    }
    
    var hasARData: Bool {
        return ar_data != nil && !ar_data!.isEmpty
    }
    
    var hasResponseText: Bool {
        return responseText != nil && !responseText!.isEmpty
    }
}

// MARK: - 3D AR Object (Future Enhancement)
struct AR3DObject: Identifiable {
    let id = UUID()
    let label: String
    let position: SIMD3<Float> // 3D position
    let rotation: SIMD3<Float> // 3D rotation
    let scale: SIMD3<Float>   // 3D scale
    let color: Color
    let confidence: Float
    
    // Convert from 2D AR object
    init(from arObject: ARObject, depth: Float = 0.0) {
        self.label = arObject.label
        self.position = SIMD3<Float>(
            Float(arObject.box_x),
            Float(arObject.box_y),
            depth
        )
        self.rotation = SIMD3<Float>(0, 0, 0)
        self.scale = SIMD3<Float>(1, 1, 1)
        self.color = arObject.displayColor
        self.confidence = 0.8 // Default confidence
    }
}