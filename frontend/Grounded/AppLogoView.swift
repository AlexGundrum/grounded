import SwiftUI

// MARK: - App Logo View
struct AppLogoView: View {
    let size: CGFloat
    let showGlow: Bool
    
    init(size: CGFloat = 200, showGlow: Bool = true) {
        self.size = size
        self.showGlow = showGlow
    }
    
    var body: some View {
        HStack(spacing: -8) {
            // "GR" text
            Text("GR")
                .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Blue orb as "O"
            ZStack {
                // Outer glow
                if showGlow {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: size * 0.1,
                                endRadius: size * 0.4
                            )
                        )
                        .frame(width: size * 0.8, height: size * 0.8)
                        .scaleEffect(1.2)
                }
                
                // Main blue orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.9),
                                Color.blue.opacity(0.7),
                                Color.blue.opacity(0.4),
                                Color.blue.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.15
                        )
                    )
                    .frame(width: size * 0.3, height: size * 0.3)
                    .shadow(color: .blue.opacity(0.8), radius: size * 0.075)
            }
            
            // "UNDED" text
            Text("UNDED")
                .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Compact Logo View (for smaller spaces)
struct CompactLogoView: View {
    let size: CGFloat
    let showGlow: Bool
    
    init(size: CGFloat = 100, showGlow: Bool = true) {
        self.size = size
        self.showGlow = showGlow
    }
    
    var body: some View {
        HStack(spacing: -4) {
            // "GR" text
            Text("GR")
                .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
            
            // Blue orb as "O"
            ZStack {
                // Outer glow
                if showGlow {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: size * 0.1,
                                endRadius: size * 0.4
                            )
                        )
                        .frame(width: size * 0.8, height: size * 0.8)
                        .scaleEffect(1.2)
                }
                
                // Main blue orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.9),
                                Color.blue.opacity(0.7),
                                Color.blue.opacity(0.4),
                                Color.blue.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.15
                        )
                    )
                    .frame(width: size * 0.3, height: size * 0.3)
                    .shadow(color: .blue.opacity(0.8), radius: size * 0.075)
            }
            
            // "UNDED" text
            Text("UNDED")
                .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Animated Logo View (with pulsing orb)
struct AnimatedLogoView: View {
    let size: CGFloat
    @State private var isPulsing = false
    
    init(size: CGFloat = 200) {
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: -8) {
            // "GR" text
            Text("GR")
                .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Animated blue orb as "O"
            ZStack {
                // Outer glow with animation
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(isPulsing ? 0.8 : 0.6),
                                Color.white.opacity(isPulsing ? 0.5 : 0.3),
                                Color.white.opacity(isPulsing ? 0.2 : 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.1,
                            endRadius: size * 0.4
                        )
                    )
                    .frame(width: size * 0.8, height: size * 0.8)
                    .scaleEffect(isPulsing ? 1.4 : 1.2)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                
                // Main blue orb with animation
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(isPulsing ? 1.0 : 0.9),
                                Color.blue.opacity(isPulsing ? 0.8 : 0.7),
                                Color.blue.opacity(isPulsing ? 0.6 : 0.4),
                                Color.blue.opacity(isPulsing ? 0.3 : 0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.15
                        )
                    )
                    .frame(width: size * 0.3, height: size * 0.3)
                    .shadow(color: .blue.opacity(isPulsing ? 1.0 : 0.8), radius: isPulsing ? size * 0.1 : size * 0.075)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
            }
            
            // "UNDED" text
            Text("UNDED")
                .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Underwater background for context
        LinearGradient(
            colors: [.blue.opacity(0.8), .cyan.opacity(0.6), .teal.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 40) {
            // Large animated logo
            AnimatedLogoView(size: 200)
            
            // Medium static logo
            AppLogoView(size: 150, showGlow: true)
            
            // Small compact logo
            CompactLogoView(size: 80, showGlow: false)
        }
    }
}