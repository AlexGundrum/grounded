//
//  PingARSystem.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import Foundation
import SwiftUI

// MARK: - COCO Classes (from your backend)
struct COCOClasses {
    static let classes = [
        0: "person", 1: "bicycle", 2: "car", 3: "motorcycle", 4: "airplane", 5: "bus",
        6: "train", 7: "truck", 8: "boat", 9: "traffic light", 10: "fire hydrant",
        11: "stop sign", 12: "parking meter", 13: "bench", 14: "bird", 15: "cat",
        16: "dog", 17: "horse", 18: "sheep", 19: "cow", 20: "elephant", 21: "bear",
        22: "zebra", 23: "giraffe", 24: "backpack", 25: "umbrella", 26: "handbag",
        27: "tie", 28: "suitcase", 29: "frisbee", 30: "skis", 31: "snowboard",
        32: "sports ball", 33: "kite", 34: "baseball bat", 35: "baseball glove",
        36: "skateboard", 37: "surfboard", 38: "tennis racket", 39: "bottle",
        40: "wine glass", 41: "cup", 42: "fork", 43: "knife", 44: "spoon", 45: "bowl",
        46: "banana", 47: "apple", 48: "sandwich", 49: "orange", 50: "broccoli",
        51: "carrot", 52: "hot dog", 53: "pizza", 54: "donut", 55: "cake", 56: "chair",
        57: "couch", 58: "potted plant", 59: "bed", 60: "dining table", 61: "toilet",
        62: "tv", 63: "laptop", 64: "mouse", 65: "remote", 66: "keyboard", 67: "cell phone",
        68: "microwave", 69: "oven", 70: "toaster", 71: "sink", 72: "refrigerator",
        73: "book", 74: "clock", 75: "vase", 76: "scissors", 77: "teddy bear",
        78: "hair drier", 79: "toothbrush"
    ]
    
    static func getClassName(for classId: Int) -> String {
        return classes[classId] ?? "unknown"
    }
}

// MARK: - Ping AR Object
struct PingARObject: Identifiable {
    let id = UUID()
    let classId: Int
    let className: String
    let box_x: Double
    let box_y: Double
    let confidence: Double
    let timestamp: Date
    
    // Computed properties
    var normalizedX: Double { box_x }
    var normalizedY: Double { box_y }
    
    // Color based on object type
    var pingColor: Color {
        switch className {
        case "person":
            return Color.blue
        case "chair", "couch", "bed", "dining table":
            return Color.brown
        case "potted plant", "tree":
            return Color.green
        case "tv", "laptop", "cell phone", "keyboard", "mouse":
            return Color.purple
        case "bottle", "cup", "wine glass", "bowl":
            return Color.orange
        case "book", "clock", "vase":
            return Color.gray
        default:
            return Color(red: 0.15, green: 0.45, blue: 0.50)  // Sea green
        }
    }
}

// MARK: - Ping AR Manager
class PingARManager: ObservableObject {
    @Published var detectedObjects: [PingARObject] = []
    @Published var pingObjects: [PingARObject] = [] // Objects to ping
    @Published var isProcessing = false
    @Published var lastUpdateTime: Date?
    
    private var updateTimer: Timer?
    var currentPhase: CrisisPhase = .computerVision
    private let cvUpdateInterval: TimeInterval = 1.0 // 1 second for CV phase
    private let arUpdateInterval: TimeInterval = 3.0 // 3 seconds for AR phase
    private let serverIP = "100.66.12.253"
    private let serverPort = "2419"
    
    enum CrisisPhase {
        case computerVision  // Phase 1: CV scanning only
        case arMode          // Phase 2: AR visualization enabled
    }
    
    // Camera controller reference for REAL image capture
    weak var cameraController: ContinuousCameraViewController?
    
    // Crisis manager reference for phase coordination
    weak var crisisManager: CrisisManager?
    
    // Performance tracking
    private var frameCount = 0
    private var successfulDetections = 0
    
    func startContinuousDetection() {
        // Default to CV phase for backward compatibility
        startContinuousDetectionWithPhase(.computerVision)
    }
    
    func startContinuousDetectionWithPhase(_ phase: CrisisPhase) {
        currentPhase = phase
        let interval = phase == .computerVision ? cvUpdateInterval : arUpdateInterval
        
        print("🎯 Starting \(phase == .computerVision ? "CV scanning" : "AR mode") detection (every \(interval)s)")
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.captureAndProcessFrame()
        }
    }
    
    func stopContinuousDetection() {
        updateTimer?.invalidate()
        updateTimer = nil
        isProcessing = false
        frameCount = 0
        print("🛑 Continuous detection stopped - timer invalidated and state reset")
    }
    
    private func captureAndProcessFrame() {
        // SAFETY CHECK: Don't run detection cycles in AR mode
        guard currentPhase == .computerVision else {
            print("🚫 Detection cycle blocked - AR mode active, no detection needed")
            return
        }
        
        guard !isProcessing else {
            print("⏸️ Skipping detection - previous still processing to prevent freeze")
            return
        }
        
        // Allow more frequent detection now that AR overlays are disabled
        // guard pingObjects.count < 2 else {
        //     print("⏸️ Skipping detection - too many active pings (\(pingObjects.count))")
        //     return
        // }
        
        isProcessing = true
        frameCount += 1
        
        print("📸 Starting detection cycle \(frameCount) (every 3s)")
        
        // Capture REAL camera screenshot and send to anchor_backend for OpenCV processing
        captureCurrentFrame { [weak self] imageData in
            guard let imageData = imageData else {
                print("❌ No real camera image data received")
                self?.isProcessing = false
                return
            }
            
            print("📸 Real camera screenshot captured - sending to anchor_backend for OpenCV processing")
            self?.sendFrameForCOCODetection(imageData)
        }
    }
    
    private func captureCurrentFrame(completion: @escaping (Data?) -> Void) {
        // Get REAL camera screenshot from the camera system
        guard let cameraController = cameraController else {
            print("❌ No camera controller available - cannot capture real camera screenshot")
            completion(nil)
            return
        }
        
        print("📸 Requesting REAL camera screenshot for anchor_backend processing")
        // Use real camera controller to capture actual screenshot of what camera sees
        cameraController.captureImageForProcessing(completion: completion)
    }
    
    
    private func sendFrameForCOCODetection(_ imageData: Data) {
        let imageBase64 = imageData.base64EncodedString()
        
        let url = URL(string: "http://\(serverIP):\(serverPort)/upload_image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3.0 // 3 second timeout
        
        let payload = [
            "image": imageBase64,
            "heart_rate": 75.0,  // Add required heart_rate field as Float
            "timestamp": Date().timeIntervalSince1970,
            "frame_id": frameCount,
            "detection_type": "coco_continuous"
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("❌ Failed to serialize frame data: \(error)")
            isProcessing = false
            return
        }
        
        print("📤 Sending REAL camera screenshot (base64) to anchor_backend for OpenCV processing...")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if let error = error {
                    print("❌ anchor_backend OpenCV processing error: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("❌ No object coordinates received from anchor_backend")
                    return
                }
                
                print("📥 Received object coordinates from anchor_backend OpenCV processing")
                
                // Debug: Log raw response data
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw backend response: \(jsonString)")
                }
                
                self?.processCOCOResponse(data)
            }
        }.resume()
    }
    
    private func processCOCOResponse(_ data: Data) {
        do {
            let response = try JSONDecoder().decode(COCOResponse.self, from: data)
            
            if let detections = response.objects { // Changed from "detections" to "objects"
                // Convert backend pixel coordinates to normalized coordinates
                let newDetectedObjects = detections.map { detection in
                    // Your backend sends pixel coordinates (e.g., 1030, 1492)
                    // Need to normalize to 0.0-1.0 for AR display
                    // Assuming 1440x1920 camera resolution
                    let normalizedX = detection.box_x / 1440.0 // Convert pixel to normalized
                    let normalizedY = detection.box_y / 1920.0 // Convert pixel to normalized
                    
                    return PingARObject(
                        classId: detection.class_id,
                        className: COCOClasses.getClassName(for: detection.class_id),
                        box_x: normalizedX, // Now normalized 0.0-1.0
                        box_y: normalizedY, // Now normalized 0.0-1.0
                        confidence: detection.confidence,
                        timestamp: Date()
                    )
                }
                
                // Update detected objects with real coordinates from OpenCV
                detectedObjects = newDetectedObjects
                successfulDetections += 1
                lastUpdateTime = Date()
                
                // Increment scan count in crisis manager
                crisisManager?.incrementScanCount()
                
                print("🎯 anchor_backend OpenCV detected \(detections.count) objects:")
                for detection in detections {
                    let className = COCOClasses.getClassName(for: detection.class_id)
                    let normalizedX = detection.box_x / 1440.0
                    let normalizedY = detection.box_y / 1920.0
                    print("  📍 \(className) at pixels (\(Int(detection.box_x)), \(Int(detection.box_y))) → normalized (\(String(format: "%.2f", normalizedX)), \(String(format: "%.2f", normalizedY))) confidence: \(String(format: "%.2f", detection.confidence))")
                }
                
                // Automatically show 3D AR dots for all detected objects
                triggerAutomaticVisualization(for: newDetectedObjects)
            }
            
        } catch {
            print("❌ Failed to decode anchor_backend response: \(error)")
            print("🔍 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
        }
    }
    
    // Phase-aware visualization: CV phase logs only, AR phase shows visuals
    private func triggerAutomaticVisualization(for objects: [PingARObject]) {
        let highConfidenceObjects = objects.filter { $0.confidence > 0.8 }
        
        guard let randomObject = highConfidenceObjects.randomElement() else {
            print("🚫 No high-confidence objects to visualize")
            return
        }
        
        switch currentPhase {
        case .computerVision:
            // PHASE 1: CV scanning - only log coordinates, no AR rendering
            print("📸 CV PHASE: Detected \(randomObject.className) at (\(String(format: "%.2f", randomObject.box_x)), \(String(format: "%.2f", randomObject.box_y)))")
            print("🚫 AR rendering DISABLED during CV scanning phase")
            // Don't set pingObjects - no visual overlays during CV phase
            
        case .arMode:
            // PHASE 2: AR mode - enable full visualization
            print("✨ AR PHASE: Showing 3D ping for \(randomObject.className)")
            pingObjects = [randomObject]
            
            // Auto-clear pings after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.clearPings()
            }
        }
    }
    
    // DISABLED 3D AR to prevent freeze
    private func triggerAutomatic3DVisualization(for objects: [PingARObject]) {
        // DISABLED - 3D AR disabled to prevent video freeze
        // Only using simple 2D dots now
        print("🚫 3D AR disabled to prevent freeze - using 2D dots only")
    }
    
    // MARK: - LLM-Triggered Ping System
    
    func triggerPingForObjects(_ objectNames: [String]) {
        print("🔔 LLM triggered ping for objects: \(objectNames)")
        
        // Find matching objects from current detections
        let matchingObjects = detectedObjects.filter { object in
            objectNames.contains { name in
                object.className.lowercased().contains(name.lowercased()) ||
                name.lowercased().contains(object.className.lowercased())
            }
        }
        
        // Add to ping objects with animation
        pingObjects = matchingObjects
        
        // Auto-clear pings after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.clearPings()
        }
    }
    
    func clearPings() {
        pingObjects = []
        print("🔕 Pings cleared")
    }
    
    // MARK: - Performance Stats
    
    func getStats() -> (frameCount: Int, successRate: Double, objectCount: Int) {
        let successRate = frameCount > 0 ? Double(successfulDetections) / Double(frameCount) : 0
        return (frameCount, successRate, detectedObjects.count)
    }
    
    func resetFrameCounts() {
        frameCount = 0
        successfulDetections = 0
        print("🔄 PingARManager frame counts reset")
    }
}

// MARK: - COCO Detection Response (Updated for anchor_backend format)
struct COCOResponse: Decodable {
    let objects: [COCODetection]? // Your backend sends "objects", not "detections"
    let processing_time: Double?
    let frame_id: Int?
}

struct COCODetection: Decodable {
    let class_id: Int
    let box_x: Double // Pixel coordinates from your backend
    let box_y: Double // Pixel coordinates from your backend
    let confidence: Double
    let status: String? // Your backend includes status field
}

// MARK: - Ping AR Overlay
struct PingAROverlay: View {
    @ObservedObject var pingManager: PingARManager
    @State private var pingAnimationPhase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Silent background objects (not visible)
                ForEach(pingManager.detectedObjects) { object in
                    // These are tracked but not displayed
                    EmptyView()
                }
                
                // Ping objects (only visible when LLM triggers)
                ForEach(pingManager.pingObjects) { object in
                    PingDotView(
                        object: object,
                        screenSize: geometry.size,
                        animationPhase: pingAnimationPhase
                    )
                }
                
                // Debug info DISABLED to prevent UI freeze
                // if !pingManager.detectedObjects.isEmpty {
                //     VStack {
                //         HStack {
                //             Spacer()
                //             DebugInfoView(
                //                 objectCount: pingManager.detectedObjects.count,
                //                 pingCount: pingManager.pingObjects.count,
                //                 isProcessing: pingManager.isProcessing
                //             )
                //         }
                //         Spacer()
                //     }
                //     .padding()
                // }
            }
        }
        .onAppear {
            // DISABLE animation to prevent video freeze
            // startPingAnimation()
        }
    }
    
    private func startPingAnimation() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            pingAnimationPhase = 1.0
        }
    }
}

// MARK: - Ping Circle View (Pulsing Style)
struct PingDotView: View {
    let object: PingARObject
    let screenSize: CGSize
    let animationPhase: Double
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        let x = object.normalizedX * screenSize.width
        let y = object.normalizedY * screenSize.height
        
        VStack(spacing: 8) {
            ZStack {
                // Multiple pulsing rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(object.pingColor.opacity(0.8 - Double(ring) * 0.2), lineWidth: 3)
                        .frame(width: 60 + CGFloat(ring) * 20, height: 60 + CGFloat(ring) * 20)
                        .scaleEffect(pulseScale + CGFloat(ring) * 0.1)
                        .opacity(opacity - Double(ring) * 0.2)
                }
                
                // Center dot
                Circle()
                    .fill(object.pingColor)
                    .frame(width: 12, height: 12)
            }
            
            // Ping label
            Text(object.className)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(object.pingColor.opacity(0.9))
                )
        }
        .position(x: x, y: y)
        .onAppear {
            // DISABLE all animations to prevent video freeze
            // startPingAnimation()
        }
    }
    
    private func startPingAnimation() {
        // MINIMAL animation to prevent UI freeze
        withAnimation(.easeInOut(duration: 1.5)) {
            pulseScale = 1.2 // Gentle pulse
            opacity = 0.8 // Subtle fade
        }
        
        // Very quick fade to minimize UI load
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0.0
            }
        }
    }
}

// MARK: - Debug Info View
struct DebugInfoView: View {
    let objectCount: Int
    let pingCount: Int
    let isProcessing: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "viewfinder")
                    .font(.caption2)
                Text("\(objectCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            
            if pingCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                    Text("\(pingCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.yellow)
            }
            
            if isProcessing {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 4, height: 4)
                    Text("Processing")
                        .font(.caption2)
                }
                .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
        )
    }
}