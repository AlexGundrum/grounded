//
//  EnhancedAROverlay.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import SwiftUI
import ARKit

// MARK: - Enhanced AR Overlay System
struct EnhancedAROverlay: View {
    @ObservedObject var arManager: RealTimeARManager
    @State private var animationPhase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Real-time object overlays
                ForEach(arManager.detectedObjects) { object in
                    RealTimeARObjectOverlay(
                        object: object,
                        screenSize: geometry.size,
                        animationPhase: animationPhase
                    )
                }
                
                // Performance indicator (debug)
                if arManager.isProcessing {
                    VStack {
                        HStack {
                            Spacer()
                            ProcessingIndicator()
                        }
                        Spacer()
                    }
                    .padding()
                }
                
                // Object count indicator
                if !arManager.detectedObjects.isEmpty {
                    VStack {
                        HStack {
                            Spacer()
                            ObjectCountIndicator(count: arManager.detectedObjects.count)
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Real-Time AR Object Overlay
struct RealTimeARObjectOverlay: View {
    let object: ARObject
    let screenSize: CGSize
    let animationPhase: Double
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        let x = object.normalizedX * screenSize.width
        let y = object.normalizedY * screenSize.height
        
        ZStack {
            // Multiple detection rings for emphasis
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(
                        object.displayColor.opacity(0.8 - Double(ring) * 0.2),
                        lineWidth: 3 - CGFloat(ring)
                    )
                    .frame(width: 80 + CGFloat(ring) * 20, height: 80 + CGFloat(ring) * 20)
                    .scaleEffect(pulseScale + CGFloat(ring) * 0.1)
                    .opacity(opacity - Double(ring) * 0.2)
            }
            
            // Central dot
            Circle()
                .fill(object.displayColor)
                .frame(width: 12, height: 12)
                .scaleEffect(pulseScale)
            
            // Object label with confidence
            Text(object.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(object.displayColor.opacity(0.9))
                )
                .offset(y: 50)
            
            // Confidence indicator
            if let confidence = getConfidence(for: object) {
                Text("\(Int(confidence * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.7))
                    )
                    .offset(y: 70)
            }
        }
        .position(x: x, y: y)
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            opacity = 0.6
        }
    }
    
    private func getConfidence(for object: ARObject) -> Double? {
        // This would come from the backend confidence scores
        // For now, return a simulated confidence
        return 0.85
    }
}

// MARK: - Processing Indicator
struct ProcessingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(red: 0.15, green: 0.45, blue: 0.50))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Object Count Indicator
struct ObjectCountIndicator: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "viewfinder")
                .font(.caption)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
        )
    }
}

// MARK: - 3D AR Overlay (Future Enhancement)
struct AR3DOverlay: View {
    let objects3D: [AR3DObject]
    
    var body: some View {
        // This would integrate with ARKit for true 3D rendering
        // For now, we'll show a placeholder
        VStack {
            Text("3D AR Mode")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("\(objects3D.count) 3D objects detected")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
        )
    }
}

// MARK: - AR Visualization Options
enum ARVisualizationMode {
    case dots          // Simple dots
    case circles       // Pulsing circles (current)
    case boxes         // Bounding boxes
    case labels        // Just labels
    case threeD        // 3D objects (future)
}

struct ARVisualizationSelector: View {
    @Binding var selectedMode: ARVisualizationMode
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach([ARVisualizationMode.dots, .circles, .boxes, .labels], id: \.self) { mode in
                Button(action: {
                    selectedMode = mode
                }) {
                    Text(modeDisplayName(mode))
                        .font(.caption)
                        .foregroundColor(selectedMode == mode ? .white : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedMode == mode ? Color(red: 0.15, green: 0.45, blue: 0.50) : Color.clear)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
        )
    }
    
    private func modeDisplayName(_ mode: ARVisualizationMode) -> String {
        switch mode {
        case .dots: return "Dots"
        case .circles: return "Circles"
        case .boxes: return "Boxes"
        case .labels: return "Labels"
        case .threeD: return "3D"
        }
    }
}