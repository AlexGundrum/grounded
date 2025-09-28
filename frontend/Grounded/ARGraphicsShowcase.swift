//
//  ARGraphicsShowcase.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import SwiftUI
import CoreGraphics

// MARK: - AR Graphics Showcase
struct ARGraphicsShowcase: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStyle: ARVisualizationStyle = .minimalDots
    @State private var isAnimating = false
    @State private var showMultipleObjects = true
    
    let mockObjects = [
        MockARObject(label: "Table", x: 0.3, y: 0.6, color: .brown, confidence: 0.95),
        MockARObject(label: "Lamp", x: 0.7, y: 0.3, color: .red, confidence: 0.87),
        MockARObject(label: "Window", x: 0.2, y: 0.2, color: .blue, confidence: 0.92),
        MockARObject(label: "Plant", x: 0.8, y: 0.7, color: .green, confidence: 0.78),
        MockARObject(label: "Chair", x: 0.5, y: 0.8, color: .brown, confidence: 0.89)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Style Selector
                StyleSelector(selectedStyle: $selectedStyle)
                
                // AR Preview Area
                ZStack {
                    // Simulated camera background
                    CameraBackgroundView()
                    
                    // AR Graphics Overlay
                    ARGraphicsOverlay(
                        objects: showMultipleObjects ? mockObjects : [mockObjects[0]],
                        style: selectedStyle,
                        isAnimating: isAnimating
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                
                // Controls
                VStack(spacing: 15) {
                    Toggle("Show Multiple Objects", isOn: $showMultipleObjects)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isAnimating.toggle()
                        }
                    }) {
                        Text(isAnimating ? "Stop Animation" : "Start Animation")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(red: 0.15, green: 0.45, blue: 0.50))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.8))
            }
            .navigationTitle("AR Graphics Showcase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.50))
                }
            }
        }
    }
}

// MARK: - Style Selector
struct StyleSelector: View {
    @Binding var selectedStyle: ARVisualizationStyle
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ARVisualizationStyle.allCases, id: \.self) { style in
                    StyleButton(
                        style: style,
                        isSelected: selectedStyle == style,
                        action: { selectedStyle = style }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(red: 0.70, green: 0.85, blue: 0.80))
    }
}

struct StyleButton: View {
    let style: ARVisualizationStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: style.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color(red: 0.15, green: 0.45, blue: 0.50))
                
                Text(style.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : Color(red: 0.05, green: 0.15, blue: 0.35))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.15, green: 0.45, blue: 0.50) : Color.white)
            )
        }
    }
}

// MARK: - Camera Background View
struct CameraBackgroundView: View {
    var body: some View {
        ZStack {
            // Simulated camera feed background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.1),
                    Color(red: 0.05, green: 0.05, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Simulated room elements
            VStack {
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 80)
                        .cornerRadius(8)
                }
                Spacer()
                HStack {
                    Rectangle()
                        .fill(Color.brown.opacity(0.4))
                        .frame(width: 120, height: 60)
                        .cornerRadius(8)
                    Spacer()
                    Circle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 40, height: 40)
                }
            }
            .padding()
        }
    }
}

// MARK: - AR Graphics Overlay
struct ARGraphicsOverlay: View {
    let objects: [MockARObject]
    let style: ARVisualizationStyle
    let isAnimating: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(objects) { object in
                    ARGraphicRenderer(
                        object: object,
                        screenSize: geometry.size,
                        style: style,
                        isAnimating: isAnimating
                    )
                }
            }
        }
    }
}

// MARK: - AR Graphic Renderer
struct ARGraphicRenderer: View {
    let object: MockARObject
    let screenSize: CGSize
    let style: ARVisualizationStyle
    let isAnimating: Bool
    
    @State private var animationPhase: Double = 0
    
    var body: some View {
        let x = object.x * screenSize.width
        let y = object.y * screenSize.height
        
        ZStack {
            switch style {
            case .minimalDots:
                MinimalDotView(object: object, isAnimating: isAnimating)
            case .pulsingCircles:
                PulsingCircleView(object: object, isAnimating: isAnimating)
            case .boundingBoxes:
                BoundingBoxView(object: object, isAnimating: isAnimating)
            case .neonGlow:
                NeonGlowView(object: object, isAnimating: isAnimating)
            case .particleSystem:
                ParticleSystemView(object: object, isAnimating: isAnimating)
            case .holographic:
                HolographicView(object: object, isAnimating: isAnimating)
            case .minimalist:
                MinimalistView(object: object, isAnimating: isAnimating)
            case .cyberpunk:
                CyberpunkView(object: object, isAnimating: isAnimating)
            }
        }
        .position(x: x, y: y)
        .onAppear {
            if isAnimating {
                startAnimation()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Visualization Styles
enum ARVisualizationStyle: CaseIterable {
    case minimalDots
    case pulsingCircles
    case boundingBoxes
    case neonGlow
    case particleSystem
    case holographic
    case minimalist
    case cyberpunk
    
    var displayName: String {
        switch self {
        case .minimalDots: return "Minimal Dots"
        case .pulsingCircles: return "Pulsing Circles"
        case .boundingBoxes: return "Bounding Boxes"
        case .neonGlow: return "Neon Glow"
        case .particleSystem: return "Particles"
        case .holographic: return "Holographic"
        case .minimalist: return "Minimalist"
        case .cyberpunk: return "Cyberpunk"
        }
    }
    
    var iconName: String {
        switch self {
        case .minimalDots: return "circle.fill"
        case .pulsingCircles: return "circle.dotted"
        case .boundingBoxes: return "square"
        case .neonGlow: return "bolt.fill"
        case .particleSystem: return "sparkles"
        case .holographic: return "cube.transparent"
        case .minimalist: return "minus.circle"
        case .cyberpunk: return "hexagon.fill"
        }
    }
}

// MARK: - Mock AR Object
struct MockARObject: Identifiable {
    let id = UUID()
    let label: String
    let x: Double
    let y: Double
    let color: Color
    let confidence: Double
}

// MARK: - Visualization Components

// 1. Minimal Dots (Apple ARKit style)
struct MinimalDotView: View {
    let object: MockARObject
    let isAnimating: Bool
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(object.color)
                .frame(width: 8, height: 8)
                .scaleEffect(scale)
            
            Text(object.label)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.7))
                )
        }
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.3
                }
            }
        }
    }
}

// 2. Pulsing Circles (Current style)
struct PulsingCircleView: View {
    let object: MockARObject
    let isAnimating: Bool
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(object.color.opacity(0.8 - Double(ring) * 0.2), lineWidth: 3)
                        .frame(width: 60 + CGFloat(ring) * 20, height: 60 + CGFloat(ring) * 20)
                        .scaleEffect(pulseScale + CGFloat(ring) * 0.1)
                        .opacity(opacity - Double(ring) * 0.2)
                }
                
                Circle()
                    .fill(object.color)
                    .frame(width: 12, height: 12)
            }
            
            Text(object.label)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(object.color.opacity(0.9))
                )
        }
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.2
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    opacity = 0.6
                }
            }
        }
    }
}

// 3. Bounding Boxes (YOLO style)
struct BoundingBoxView: View {
    let object: MockARObject
    let isAnimating: Bool
    @State private var dashOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        object.color,
                        style: StrokeStyle(
                            lineWidth: 3,
                            dash: [10, 5],
                            dashPhase: dashOffset
                        )
                    )
                    .frame(width: 80, height: 60)
                
                // Corner markers
                ForEach(0..<4, id: \.self) { corner in
                    Rectangle()
                        .fill(object.color)
                        .frame(width: 8, height: 8)
                        .offset(
                            x: corner < 2 ? -36 : 36,
                            y: corner % 2 == 0 ? -26 : 26
                        )
                }
            }
            
            Text(object.label)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(object.color.opacity(0.9))
                )
        }
        .onAppear {
            if isAnimating {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    dashOffset = 15
                }
            }
        }
    }
}

// 4. Neon Glow (Cyberpunk style)
struct NeonGlowView: View {
    let object: MockARObject
    let isAnimating: Bool
    @State private var glowIntensity: Double = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(object.color.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)
                    .scaleEffect(glowIntensity)
                
                // Inner circle
                Circle()
                    .stroke(object.color, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .shadow(color: object.color, radius: 8)
                
                // Center dot
                Circle()
                    .fill(object.color)
                    .frame(width: 8, height: 8)
            }
            
            Text(object.label)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(object.color, lineWidth: 1)
                        )
                )
        }
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    glowIntensity = 1.5
                }
            }
        }
    }
}

// 5. Particle System (Magic style)
struct ParticleSystemView: View {
    let object: MockARObject
    let isAnimating: Bool
    @State private var particles: [Particle] = []
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Main object
                Circle()
                    .fill(object.color)
                    .frame(width: 16, height: 16)
                
                // Particles
                ForEach(particles) { particle in
                    Circle()
                        .fill(object.color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.x, y: particle.y)
                }
            }
            
            Text(object.label)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(object.color.opacity(0.9))
                )
        }
        .onAppear {
            if isAnimating {
                generateParticles()
                animateParticles()
            }
        }
    }
    
    private func generateParticles() {
        particles = (0..<8).map { _ in
            Particle(
                x: Double.random(in: -30...30),
                y: Double.random(in: -30...30),
                size: Double.random(in: 2...6),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            for i in particles.indices {
                particles[i].x = Double.random(in: -40...40)
                particles[i].y = Double.random(in: -40...40)
                particles[i].opacity = Double.random(in: 0.2...1.0)
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var size: Double
    var opacity: Double
}

// 6. Holographic (Sci-fi style)
struct HolographicView: View {
    let object: MockARObject
    let isAnimating: Bool
    @State private var scanLineOffset: CGFloat = -50
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Holographic frame
                RoundedRectangle(cornerRadius: 8)
                    .stroke(object.color.opacity(0.6), lineWidth: 2)
                    .frame(width: 80, height: 60)
                
                // Scan line effect
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, object.color.opacity(0.8), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 2)
                    .offset(y: scanLineOffset)
                
                // Center indicator
                Circle()
                    .fill(object.color.opacity(0.8))
                    .frame(width: 8, height: 8)
            }
            
            Text(object.label)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(object.color.opacity(0.6), lineWidth: 1)
                        )
                )
        }
        .onAppear {
            if isAnimating {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    scanLineOffset = 50
                }
            }
        }
    }
}

// 7. Minimalist (Clean style)
struct MinimalistView: View {
    let object: MockARObject
    let isAnimating: Bool
    @State private var fadeOpacity: Double = 1.0
    
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .stroke(object.color, lineWidth: 2)
                .frame(width: 20, height: 20)
                .opacity(fadeOpacity)
            
            Text(object.label)
                .font(.caption2)
                .foregroundColor(.white)
                .opacity(fadeOpacity)
        }
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    fadeOpacity = 0.3
                }
            }
        }
    }
}

// 8. Cyberpunk (Futuristic style)
struct CyberpunkView: View {
    let object: MockARObject
    let isAnimating: Bool
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Hexagonal frame
                HexagonShape()
                    .stroke(object.color, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Center dot
                Circle()
                    .fill(object.color)
                    .frame(width: 8, height: 8)
                
                // Corner accents
                ForEach(0..<6, id: \.self) { corner in
                    Rectangle()
                        .fill(object.color)
                        .frame(width: 4, height: 4)
                        .offset(
                            x: cos(Double(corner) * .pi / 3) * 25,
                            y: sin(Double(corner) * .pi / 3) * 25
                        )
                }
            }
            
            Text(object.label)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(object.color, lineWidth: 1)
                        )
                )
        }
        .onAppear {
            if isAnimating {
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
        }
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}