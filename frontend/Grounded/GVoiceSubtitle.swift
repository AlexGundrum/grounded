//
//  GVoiceSubtitle.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import SwiftUI

// MARK: - G-Voice Subtitle: Non-Intrusive Dialogue Display
struct GVoiceSubtitle: View {
    @ObservedObject var crisisManager: CrisisManager
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleScale: CGFloat = 0.8
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            Spacer()
            
            // Subtitle container
            if !crisisManager.lastAIResponse.isEmpty {
                SubtitleContainer(
                    text: crisisManager.lastAIResponse,
                    opacity: subtitleOpacity,
                    scale: subtitleScale
                )
                .onAppear {
                    showSubtitle()
                }
                .onChange(of: crisisManager.lastAIResponse) { _, newText in
                    if !newText.isEmpty {
                        updateSubtitle()
                    }
                }
            }
        }
    }
    
    private func showSubtitle() {
        withAnimation(.easeInOut(duration: 0.8)) {
            subtitleOpacity = 1.0
            subtitleScale = 1.0
        }
        
        // Auto-hide after 8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            hideSubtitle()
        }
    }
    
    private func updateSubtitle() {
        // Fade out current subtitle
        withAnimation(.easeOut(duration: 0.3)) {
            subtitleOpacity = 0
        }
        
        // Show new subtitle after fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.8)) {
                subtitleOpacity = 1.0
                subtitleScale = 1.0
            }
            
            // Auto-hide new subtitle
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                hideSubtitle()
            }
        }
    }
    
    private func hideSubtitle() {
        withAnimation(.easeOut(duration: 0.5)) {
            subtitleOpacity = 0
            subtitleScale = 0.8
        }
    }
}

// MARK: - Subtitle Container
struct SubtitleContainer: View {
    let text: String
    let opacity: Double
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: 12) {
            // Main subtitle text
            Text(text)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            
            // Breathing indicator (subtle)
            BreathingIndicator()
        }
        .opacity(opacity)
        .scaleEffect(scale)
        .padding(.horizontal, 20)
        .padding(.bottom, 120) // Position in bottom third
    }
}

// MARK: - Breathing Indicator
struct BreathingIndicator: View {
    @State private var isBreathing = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(red: 0.15, green: 0.45, blue: 0.50).opacity(0.6))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isBreathing ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isBreathing
                    )
            }
        }
        .onAppear {
            isBreathing = true
        }
    }
}

// MARK: - Enhanced Subtitle with Typing Effect
struct TypingSubtitle: View {
    let fullText: String
    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    @State private var isTyping = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Typing subtitle text
            Text(displayedText)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            
            // Typing cursor
            if isTyping {
                Text("|")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isTyping)
            }
            
            // Breathing indicator
            BreathingIndicator()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 120)
        .onAppear {
            startTyping()
        }
    }
    
    private func startTyping() {
        isTyping = true
        displayedText = ""
        currentIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                displayedText += String(fullText[index])
                currentIndex += 1
            } else {
                timer.invalidate()
                isTyping = false
            }
        }
    }
}

// MARK: - Subtitle Settings
struct SubtitleSettings {
    static let maxDisplayTime: Double = 8.0
    static let fadeInDuration: Double = 0.8
    static let fadeOutDuration: Double = 0.5
    static let typingSpeed: Double = 0.05
    static let fontSize: CGFloat = 18
    static let cornerRadius: CGFloat = 16
    static let backgroundOpacity: Double = 0.4
    static let strokeOpacity: Double = 0.2
}

// MARK: - Accessibility Subtitle
struct AccessibilitySubtitle: View {
    @ObservedObject var crisisManager: CrisisManager
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleScale: CGFloat = 0.8
    
    var body: some View {
        VStack {
            Spacer()
            
            if !crisisManager.lastAIResponse.isEmpty {
                VStack(spacing: 16) {
                    // Large, high-contrast text
                    Text(crisisManager.lastAIResponse)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        )
                    
                    // Voice status indicator
                    HStack(spacing: 8) {
                        Image(systemName: crisisManager.isTTSPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundColor(crisisManager.isTTSPlaying ? Color(red: 0.15, green: 0.45, blue: 0.50) : .gray)
                        
                        Text(crisisManager.isTTSPlaying ? "Speaking" : "Silent")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.5))
                    )
                }
                .opacity(subtitleOpacity)
                .scaleEffect(subtitleScale)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        subtitleOpacity = 1.0
                        subtitleScale = 1.0
                    }
                }
                .onChange(of: crisisManager.lastAIResponse) { _, _ in
                    // Animate subtitle updates
                    withAnimation(.easeInOut(duration: 0.5)) {
                        subtitleOpacity = 0.7
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            subtitleOpacity = 1.0
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Subtitle Manager
class SubtitleManager: ObservableObject {
    @Published var isVisible = false
    @Published var currentText = ""
    @Published var subtitleStyle: SubtitleStyle = .standard
    
    enum SubtitleStyle {
        case standard
        case typing
        case accessibility
    }
    
    func showSubtitle(_ text: String, style: SubtitleStyle = .standard) {
        currentText = text
        subtitleStyle = style
        isVisible = true
        
        // Auto-hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + SubtitleSettings.maxDisplayTime) {
            self.hideSubtitle()
        }
    }
    
    func hideSubtitle() {
        isVisible = false
    }
    
    func updateSubtitle(_ text: String) {
        currentText = text
    }
}