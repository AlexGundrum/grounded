//
//  ContentView.swift
//  Anchor
//
//  Created by Kori Russell on 9/26/25.
//

import SwiftUI
import AVKit
import AVFoundation

// MARK: - Ocean Storm Inspired Color Palette
extension Color {
    // Ocean/storm theme - deep blues, sea greens, storm grays
    static let oceanDeep = Color(red: 0.05, green: 0.15, blue: 0.35) // #0D2659 - Deep ocean blue
    static let oceanBlue = Color(red: 0.10, green: 0.30, blue: 0.55) // #1A4D8C - Ocean blue
    static let seaGreen = Color(red: 0.15, green: 0.45, blue: 0.50) // #267380 - Ghibli sea green
    static let stormGray = Color(red: 0.25, green: 0.30, blue: 0.35) // #404859 - Storm cloud gray
    static let seafoam = Color(red: 0.70, green: 0.85, blue: 0.80) // #B3D9CC - Light seafoam
    static let anchorSilver = Color(red: 0.85, green: 0.88, blue: 0.90) // #D9E0E6 - Anchor silver
    static let deepCurrent = Color(red: 0.02, green: 0.08, blue: 0.20) // #051433 - Deep current (almost black)
}

struct ContentView: View {
    @StateObject private var crisisManager = CrisisManager()
    @StateObject private var userDataManager = UserDataManager()
    @StateObject private var panicLogManager = PanicLogManager()
    @State private var showingMenu = false
    @State private var showingARShowcase = false
    @State private var showUnderwaterScene = true
    @State private var showMainInterface = false
    @State private var showingProfile = false
    @State private var showingPanicLog = false
    
    var body: some View {
        ZStack {
            if showUnderwaterScene {
                // Cinematic underwater scene
                UnderwaterSceneView(
                    crisisManager: crisisManager,
                    userDataManager: userDataManager,
                    panicLogManager: panicLogManager,
                    showingMenu: $showingMenu,
                    showingProfile: $showingProfile,
                    showingPanicLog: $showingPanicLog,
                    onAnchorPressed: {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            showUnderwaterScene = false
                            showMainInterface = true
                        }
                    }
                )
            } else if showMainInterface {
                // Main interface after underwater transition
                MainInterfaceView(
                    crisisManager: crisisManager,
                    userDataManager: userDataManager,
                    showingMenu: $showingMenu,
                    showingProfile: $showingProfile
                )
            }
        }
        .fullScreenCover(isPresented: $crisisManager.showCamera) {
            CameraViewWithOverlay(crisisManager: crisisManager)
        }
        .sheet(isPresented: $showingMenu) {
            MenuView(crisisManager: crisisManager, panicLogManager: panicLogManager, showingARShowcase: $showingARShowcase, showingPanicLog: $showingPanicLog)
        }
        .sheet(isPresented: $showingARShowcase) {
            ARGraphicsShowcase()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(userDataManager: userDataManager)
        }
        .sheet(isPresented: $showingPanicLog) {
            PanicLogView(panicLogManager: panicLogManager)
        }
    }
}

// MARK: - Menu View - Forest Style
struct MenuView: View {
    let crisisManager: CrisisManager
    let panicLogManager: PanicLogManager
    @Binding var showingARShowcase: Bool
    @Binding var showingPanicLog: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Clean header
                    VStack(spacing: 8) {
                        CustomAnchorIcon()
                            .frame(width: 50, height: 50)
                        
                        Text("Navigation")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.anchorSilver)
                    }
                    .padding(.top, 20)
                    
                    // Essential navigation options only
                    VStack(spacing: 20) {
                    
                    MenuButton(
                        icon: "arkit",
                        title: "AR Breathing Orb",
                        action: {
                            crisisManager.testBreathingRing()
                        }
                    )
                    
                    MenuButton(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Panic Attack History",
                        subtitle: "\(panicLogManager.panicLogs.count) episodes",
                        action: {
                            dismiss() // Close the menu first
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingPanicLog = true // Then open the stats
                            }
                        }
                    )
                }
                
                // Add bottom padding for better scrolling
                Spacer()
                    .frame(height: 50)
                }
                .padding(.horizontal, 20)
            }
            .background(
                LinearGradient(
                    colors: [.deepCurrent.opacity(0.9), .oceanDeep.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.seaGreen)
                }
            }
        }
    }
}

// MARK: - Clean Menu Button
struct MenuButton: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.seaGreen)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.anchorSilver)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.seafoam)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.seafoam)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.seaGreen.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.oceanDeep.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Authentic Anchor with Chain
struct AuthenticAnchorView: View {
    @State private var chainLinks: [ChainLink] = []
    @State private var anchorRotation: Double = 0
    @State private var chainSwing: Double = 0
    
    var body: some View {
        ZStack {
            // Background glow effect
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
                        startRadius: 5,
                        endRadius: 40
                    )
                )
            
            VStack(spacing: 0) {
                // Chain links
                ForEach(chainLinks.indices, id: \.self) { index in
                    ChainLinkView(link: chainLinks[index])
                        .offset(x: chainLinks[index].swingOffset)
                        .rotationEffect(.degrees(chainLinks[index].rotation))
                }
                
                // Main anchor
                AuthenticAnchorShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.7, green: 0.7, blue: 0.75), // Steel gray
                                Color(red: 0.5, green: 0.5, blue: 0.55), // Darker steel
                                Color(red: 0.3, green: 0.3, blue: 0.35)  // Dark steel
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 80)
                    .rotationEffect(.degrees(anchorRotation))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
            }
        }
        .onAppear {
            createChainLinks()
            startChainAnimation()
        }
    }
    
    private func createChainLinks() {
        chainLinks = []
        for i in 0..<8 { // 8 chain links
            chainLinks.append(ChainLink(
                id: i,
                yOffset: CGFloat(i * 12), // 12 points between each link
                swingOffset: 0,
                rotation: 0
            ))
        }
    }
    
    private func startChainAnimation() {
        // Animate chain swinging
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            chainSwing = 15
        }
        
        // Update chain link positions
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in chainLinks.indices {
                let swingAmount = sin(chainSwing * .pi / 180) * CGFloat(i + 1) * 2
                chainLinks[i].swingOffset = swingAmount
                chainLinks[i].rotation = swingAmount * 0.5
            }
        }
    }
}

// MARK: - Chain Link Model
struct ChainLink {
    let id: Int
    var yOffset: CGFloat
    var swingOffset: CGFloat
    var rotation: Double
}

// MARK: - Chain Link View
struct ChainLinkView: View {
    let link: ChainLink
    
    var body: some View {
        ChainLinkShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.6, green: 0.6, blue: 0.65),
                        Color(red: 0.4, green: 0.4, blue: 0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 16, height: 20)
            .offset(y: link.yOffset)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
    }
}

// MARK: - Chain Link Shape
struct ChainLinkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Create oval chain link
        let linkRect = CGRect(
            x: width * 0.1,
            y: height * 0.1,
            width: width * 0.8,
            height: height * 0.8
        )
        
        path.addEllipse(in: linkRect)
        
        // Add inner hole
        let innerRect = CGRect(
            x: width * 0.3,
            y: height * 0.3,
            width: width * 0.4,
            height: height * 0.4
        )
        path.addEllipse(in: innerRect)
        
        return path
    }
}

// MARK: - Authentic Anchor Shape
struct AuthenticAnchorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let centerX = width * 0.5
        
        // Anchor ring (shackle) - top
        let ringCenter = CGPoint(x: centerX, y: height * 0.08)
        let ringRadius = width * 0.08
        
        path.addEllipse(in: CGRect(
            x: ringCenter.x - ringRadius,
            y: ringCenter.y - ringRadius,
            width: ringRadius * 2,
            height: ringRadius * 2
        ))
        
        // Inner ring hole
        path.addEllipse(in: CGRect(
            x: ringCenter.x - ringRadius * 0.4,
            y: ringCenter.y - ringRadius * 0.4,
            width: ringRadius * 0.8,
            height: ringRadius * 0.8
        ))
        
        // Anchor shank (vertical shaft) - thicker and more realistic
        let shankWidth = width * 0.08
        let shankRect = CGRect(
            x: centerX - shankWidth/2,
            y: height * 0.18,
            width: shankWidth,
            height: height * 0.5
        )
        path.addRoundedRect(in: shankRect, cornerSize: CGSize(width: shankWidth/2, height: shankWidth/2))
        
        // Stock (crossbar) - horizontal bar
        let stockY = height * 0.68
        let stockWidth = width * 0.6
        let stockThickness = width * 0.08
        let stockRect = CGRect(
            x: centerX - stockWidth/2,
            y: stockY - stockThickness/2,
            width: stockWidth,
            height: stockThickness
        )
        path.addRoundedRect(in: stockRect, cornerSize: CGSize(width: stockThickness/2, height: stockThickness/2))
        
        // Left fluke (curved hook) - more realistic shape
        let leftFlukeCenter = CGPoint(x: centerX - stockWidth/2, y: stockY)
        let flukeRadius = width * 0.12
        let flukeThickness = width * 0.06
        
        // Left fluke curve - more pronounced
        path.move(to: CGPoint(x: leftFlukeCenter.x, y: leftFlukeCenter.y))
        path.addQuadCurve(
            to: CGPoint(x: leftFlukeCenter.x - flukeRadius, y: leftFlukeCenter.y + flukeRadius * 1.2),
            control: CGPoint(x: leftFlukeCenter.x - flukeRadius * 0.8, y: leftFlukeCenter.y)
        )
        path.addQuadCurve(
            to: CGPoint(x: leftFlukeCenter.x - flukeRadius + flukeThickness, y: leftFlukeCenter.y + flukeRadius * 1.2 - flukeThickness),
            control: CGPoint(x: leftFlukeCenter.x - flukeRadius + flukeThickness/2, y: leftFlukeCenter.y + flukeRadius * 1.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: leftFlukeCenter.x, y: leftFlukeCenter.y),
            control: CGPoint(x: leftFlukeCenter.x - flukeRadius/2, y: leftFlukeCenter.y)
        )
        
        // Right fluke (curved hook)
        let rightFlukeCenter = CGPoint(x: centerX + stockWidth/2, y: stockY)
        
        path.move(to: CGPoint(x: rightFlukeCenter.x, y: rightFlukeCenter.y))
        path.addQuadCurve(
            to: CGPoint(x: rightFlukeCenter.x + flukeRadius, y: rightFlukeCenter.y + flukeRadius * 1.2),
            control: CGPoint(x: rightFlukeCenter.x + flukeRadius * 0.8, y: rightFlukeCenter.y)
        )
        path.addQuadCurve(
            to: CGPoint(x: rightFlukeCenter.x + flukeRadius - flukeThickness, y: rightFlukeCenter.y + flukeRadius * 1.2 - flukeThickness),
            control: CGPoint(x: rightFlukeCenter.x + flukeRadius - flukeThickness/2, y: rightFlukeCenter.y + flukeRadius * 1.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: rightFlukeCenter.x, y: rightFlukeCenter.y),
            control: CGPoint(x: rightFlukeCenter.x + flukeRadius/2, y: rightFlukeCenter.y)
        )
        
        // Crown (bottom point) - sharp tip
        let crownPoint = CGPoint(x: centerX, y: height * 0.95)
        path.move(to: CGPoint(x: centerX, y: height * 0.68 + stockThickness/2))
        path.addLine(to: crownPoint)
        
        return path
    }
}

// MARK: - Custom Anchor Icon (for menu/logo use)
struct CustomAnchorIcon: View {
    @State private var glowScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background glow effect - white illuminating like water droplet
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 30
                    )
                )
            
            // Gradient blue pulsing orb
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
                        endRadius: 15
                    )
                )
                .frame(width: 30, height: 30)
                .scaleEffect(glowScale)
                .shadow(color: .blue.opacity(0.8), radius: 8)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowScale = 1.2
                    }
                }
        }
    }
}

// MARK: - Anchor Shape
struct AnchorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let centerX = width * 0.5
        
        // Anchor ring (top) - larger and more prominent
        let ringCenter = CGPoint(x: centerX, y: height * 0.15)
        let ringOuterRadius = width * 0.12
        let ringInnerRadius = width * 0.08
        
        // Outer ring
        path.addEllipse(in: CGRect(
            x: ringCenter.x - ringOuterRadius,
            y: ringCenter.y - ringOuterRadius,
            width: ringOuterRadius * 2,
            height: ringOuterRadius * 2
        ))
        
        // Inner ring (subtract to create hole)
        path.addEllipse(in: CGRect(
            x: ringCenter.x - ringInnerRadius,
            y: ringCenter.y - ringInnerRadius,
            width: ringInnerRadius * 2,
            height: ringInnerRadius * 2
        ))
        
        // Anchor shank (vertical shaft) - thicker
        let shankWidth = width * 0.04
        let shankRect = CGRect(
            x: centerX - shankWidth/2,
            y: height * 0.27,
            width: shankWidth,
            height: height * 0.45
        )
        path.addRoundedRect(in: shankRect, cornerSize: CGSize(width: shankWidth/2, height: shankWidth/2))
        
        // Anchor arms (crossbar) - thicker and more defined
        let armY = height * 0.72
        let armWidth = width * 0.5
        let armThickness = width * 0.06
        let armRect = CGRect(
            x: centerX - armWidth/2,
            y: armY - armThickness/2,
            width: armWidth,
            height: armThickness
        )
        path.addRoundedRect(in: armRect, cornerSize: CGSize(width: armThickness/2, height: armThickness/2))
        
        // Left fluke (curved hook)
        let leftFlukeCenter = CGPoint(x: centerX - armWidth/2, y: armY)
        let flukeRadius = width * 0.08
        let flukeThickness = width * 0.04
        
        // Left fluke curve
        path.move(to: CGPoint(x: leftFlukeCenter.x, y: leftFlukeCenter.y))
        path.addQuadCurve(
            to: CGPoint(x: leftFlukeCenter.x - flukeRadius, y: leftFlukeCenter.y + flukeRadius),
            control: CGPoint(x: leftFlukeCenter.x - flukeRadius, y: leftFlukeCenter.y)
        )
        path.addQuadCurve(
            to: CGPoint(x: leftFlukeCenter.x - flukeRadius + flukeThickness, y: leftFlukeCenter.y + flukeRadius - flukeThickness),
            control: CGPoint(x: leftFlukeCenter.x - flukeRadius + flukeThickness/2, y: leftFlukeCenter.y + flukeRadius)
        )
        path.addQuadCurve(
            to: CGPoint(x: leftFlukeCenter.x, y: leftFlukeCenter.y),
            control: CGPoint(x: leftFlukeCenter.x - flukeRadius/2, y: leftFlukeCenter.y)
        )
        
        // Right fluke (curved hook)
        let rightFlukeCenter = CGPoint(x: centerX + armWidth/2, y: armY)
        
        path.move(to: CGPoint(x: rightFlukeCenter.x, y: rightFlukeCenter.y))
        path.addQuadCurve(
            to: CGPoint(x: rightFlukeCenter.x + flukeRadius, y: rightFlukeCenter.y + flukeRadius),
            control: CGPoint(x: rightFlukeCenter.x + flukeRadius, y: rightFlukeCenter.y)
        )
        path.addQuadCurve(
            to: CGPoint(x: rightFlukeCenter.x + flukeRadius - flukeThickness, y: rightFlukeCenter.y + flukeRadius - flukeThickness),
            control: CGPoint(x: rightFlukeCenter.x + flukeRadius - flukeThickness/2, y: rightFlukeCenter.y + flukeRadius)
        )
        path.addQuadCurve(
            to: CGPoint(x: rightFlukeCenter.x, y: rightFlukeCenter.y),
            control: CGPoint(x: rightFlukeCenter.x + flukeRadius/2, y: rightFlukeCenter.y)
        )
        
        return path
    }
}

// MARK: - Custom Anchor Shape (AuthenticAnchorShape Replacement)
struct RealisticAnchorShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Define the geometry of the anchor here.
        // For simplicity, this is a stylized example.
        // You would replace this with the geometry matching your custom sprite.
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        
        // Anchor Shank (vertical line)
        path.addRoundedRect(in: CGRect(x: width * 0.45, y: 0, width: width * 0.1, height: height * 0.7), cornerSize: CGSize(width: 5, height: 5))
        
        // Anchor Stock/Crown (horizontal bar at the top)
        path.addRoundedRect(in: CGRect(x: width * 0.3, y: height * 0.05, width: width * 0.4, height: height * 0.05), cornerSize: CGSize(width: 3, height: 3))
        
        // Anchor Flukes (curved bottom arms)
        path.move(to: CGPoint(x: width * 0.45, y: height * 0.7))
        path.addQuadCurve(to: CGPoint(x: width * 0.2, y: height * 0.95), control: CGPoint(x: width * 0.3, y: height * 0.8))
        path.addQuadCurve(to: CGPoint(x: width * 0.55, y: height * 0.7), control: CGPoint(x: width * 0.4, y: height * 0.8))
        
        path.move(to: CGPoint(x: width * 0.55, y: height * 0.7))
        path.addQuadCurve(to: CGPoint(x: width * 0.8, y: height * 0.95), control: CGPoint(x: width * 0.7, y: height * 0.8))
        path.addQuadCurve(to: CGPoint(x: width * 0.45, y: height * 0.7), control: CGPoint(x: width * 0.6, y: height * 0.8))
        
        return path
    }
}

// MARK: - Cinematic Underwater Scene
struct UnderwaterSceneView: View {
    @ObservedObject var crisisManager: CrisisManager
    @ObservedObject var userDataManager: UserDataManager
    @ObservedObject var panicLogManager: PanicLogManager
    @Binding var showingMenu: Bool
    @Binding var showingProfile: Bool
    @Binding var showingPanicLog: Bool
    let onAnchorPressed: () -> Void
    
    @State private var isAnimating = true
    @State private var showGlowingAnchor = false
    @State private var anchorOffset: CGFloat = 0
    @State private var menuOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Underwater background with depth
            UnderwaterBackgroundView(isAnimating: isAnimating)
                .opacity(backgroundOpacity)
            
            // Friends bubbles in background
            FloatingFriendsView(friends: userDataManager.friends)
                .opacity(menuOpacity * 0.6) // Semi-transparent background bubbles that fade with menu
            
            // Moving sea life and debris
            if isAnimating {
                SeaLifeView()
            }
            
            // Glowing anchor (appears when button is pressed)
            if showGlowingAnchor {
                GlowingAnchorView()
                    .offset(y: anchorOffset)
                    .animation(.easeInOut(duration: 3.0), value: anchorOffset)
            }
            
            // Centered Anchor Text
            Text("Anchor")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                .opacity(menuOpacity)
                .offset(y: -100) // Raise the text higher
            
            // UI Elements
            VStack {
                // Top row: Profile and Menu
                HStack {
                    // Profile Circle
                    Button(action: {
                        showingProfile = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.seaGreen, .oceanBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: userDataManager.currentUser.profileImage)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .seaGreen.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .opacity(menuOpacity)
                    
                    Spacer()
                    
                    Button(action: {
                        showingMenu = true
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.7)
                            )
                    }
                    .opacity(menuOpacity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Tappable blue orb in center (replaces anchor button)
                Button(action: {
                    startAnchorSequence()
                }) {
                    ZStack {
                        // Outer glow
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
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(1.2)
                        
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
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .blue.opacity(0.8), radius: 15)
                    }
                    .opacity(menuOpacity)
                    .scaleEffect(menuOpacity)
                    .animation(.easeInOut(duration: 1.0), value: menuOpacity)
                }
                
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    private func startAnchorSequence() {
        // Stop all animations
        isAnimating = false
        
        // Fade out menu elements
        withAnimation(.easeInOut(duration: 1.0)) {
            menuOpacity = 0.0
        }
        
        // Show anchor in center immediately
        showGlowingAnchor = true
        
        // Fade background and transition directly to camera
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                backgroundOpacity = 0.0
            }
        }
        
        // Complete transition - go directly to camera
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            // Start crisis mode directly
            crisisManager.initiateCrisisProtocol()
        }
    }
}

// MARK: - Underwater Background
struct UnderwaterBackgroundView: View {
    let isAnimating: Bool
    @State private var bubbleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Ocean depth gradient (looking up from below)
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.1, blue: 0.3), // Deep abyss
                    Color(red: 0.05, green: 0.2, blue: 0.4), // Mid depth
                    Color(red: 0.1, green: 0.3, blue: 0.6),  // Upper water
                    Color(red: 0.2, green: 0.5, blue: 0.8)   // Near surface
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
                    // Light rays removed per user request
            
            // Floating bubbles
            if isAnimating {
                BubblesView(offset: bubbleOffset)
            }
        }
        .onAppear {
            if isAnimating {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        // Animate bubbles
        withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
            bubbleOffset = 1.0
        }
    }
}


// MARK: - Floating Bubbles
struct BubblesView: View {
    let offset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<15, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: CGFloat.random(in: 8...20))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: geometry.size.height - (offset * geometry.size.height * 1.5) + CGFloat(i * 50)
                        )
                        .animation(.linear(duration: Double.random(in: 3...8)).repeatForever(autoreverses: false), value: offset)
                }
            }
        }
    }
}

// MARK: - Sea Life View
struct SeaLifeView: View {
    @State private var fishOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fish swimming left
                ForEach(0..<8, id: \.self) { i in
                    FishView(fishType: FishView.FishType.allCases.randomElement() ?? .blue1)
                        .position(
                            x: geometry.size.width + (fishOffset * geometry.size.width * 1.5) + CGFloat(i * 80),
                            y: CGFloat.random(in: 100...geometry.size.height - 200)
                        )
                        .animation(.linear(duration: Double.random(in: 8...15)).repeatForever(autoreverses: false), value: fishOffset)
                }
                
                // Debris removed as requested
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            fishOffset = 1.0
        }
    }
}

// MARK: - Fish View
struct FishView: View {
    let fishType: FishType
    
    enum FishType: CaseIterable {
        case blue1, blue2, yellowStriped, magenta
        
        var colors: (body: Color, tail: Color, eye: Color) {
            switch self {
            case .blue1:
                return (Color(red: 0.3, green: 0.6, blue: 0.9), Color(red: 0.2, green: 0.4, blue: 0.7), Color.white)
            case .blue2:
                return (Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.3, blue: 0.6), Color.white)
            case .yellowStriped:
                return (Color(red: 0.9, green: 0.8, blue: 0.3), Color(red: 0.8, green: 0.6, blue: 0.2), Color.white)
            case .magenta:
                return (Color(red: 0.9, green: 0.3, blue: 0.7), Color(red: 0.7, green: 0.2, blue: 0.5), Color.white)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Fish body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [fishType.colors.body, fishType.colors.tail],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 25, height: 15)
            
            // Fish tail
            Triangle()
                .fill(fishType.colors.tail)
                .frame(width: 8, height: 12)
                .offset(x: -12, y: 0)
            
            // Fish eye
            Circle()
                .fill(fishType.colors.eye)
                .frame(width: 4, height: 4)
                .offset(x: 5, y: -2)
            
            Circle()
                .fill(Color.black)
                .frame(width: 2, height: 2)
                .offset(x: 6, y: -2)
            
            // Stripes for yellow fish
            if fishType == .yellowStriped {
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 2, height: 15)
                        .offset(x: CGFloat(i * 3 - 3), y: 0)
                }
            }
        }
        .frame(width: 30, height: 20)
    }
}

// MARK: - Debris View
struct DebrisView: View {
    let debrisType: DebrisType
    
    enum DebrisType: CaseIterable {
        case wood1, wood2, wood3, seaweed1, seaweed2
        
        var color: Color {
            switch self {
            case .wood1, .wood2, .wood3:
                return Color(red: 0.4, green: 0.3, blue: 0.2)
            case .seaweed1, .seaweed2:
                return Color(red: 0.1, green: 0.4, blue: 0.2)
            }
        }
    }
    
    var body: some View {
        ZStack {
            if debrisType == .wood1 || debrisType == .wood2 || debrisType == .wood3 {
                // Wooden debris
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                debrisType.color,
                                Color(red: 0.3, green: 0.2, blue: 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 20, height: 8)
                    .rotationEffect(.degrees(45))
            } else {
                // Seaweed
                Path { path in
                    path.move(to: CGPoint(x: 12, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: 8, y: 20),
                        control: CGPoint(x: 15, y: 10)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: 12, y: 0),
                        control: CGPoint(x: 5, y: 10)
                    )
                }
                .fill(debrisType.color)
                .frame(width: 15, height: 20)
            }
        }
        .frame(width: 25, height: 25)
    }
}

// MARK: - Dropping Anchor
struct GlowingAnchorView: View {
    @State private var glowIntensity: Double = 0.5
    @State private var glowScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Outer glow
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
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(glowIntensity * 1.2 + 0.8)
            
            // Gradient blue pulsing orb
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
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
                .scaleEffect(glowScale)
                .shadow(color: .blue.opacity(0.8), radius: 15)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowScale = 1.3
                    }
                }
        }
        .onAppear {
            startGlowAnimation()
        }
    }
    
    private func startGlowAnimation() {
        // Pulsing glow
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }
}

// MARK: - Wave View
struct WaveView: View {
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        Path { path in
            let width = UIScreen.main.bounds.width
            let height: CGFloat = 100
            
            path.move(to: CGPoint(x: 0, y: height * 0.5))
            
            for x in stride(from: 0, through: width, by: 1) {
                let relativeX = x / width
                let sine = sin((relativeX * .pi * 4) + waveOffset)
                let y = height * 0.5 + sine * 15
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                waveOffset = .pi * 2
            }
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Main Interface View
struct MainInterfaceView: View {
    @ObservedObject var crisisManager: CrisisManager
    @ObservedObject var userDataManager: UserDataManager
    @Binding var showingMenu: Bool
    @Binding var showingProfile: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with profile and friends
            VStack(spacing: 15) {
                // Top row: Profile and Menu
                HStack {
                    // Profile Circle
                    Button(action: {
                        showingProfile = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.seaGreen, .oceanBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: userDataManager.currentUser.profileImage)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .seaGreen.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingMenu = true
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.anchorSilver)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Friends List
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(userDataManager.friends) { friend in
                            FriendCircleView(friend: friend)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
            
            // Main content - Clean and minimal
            VStack(spacing: 30) {
                // App icon/title - Centered anchor
                VStack(spacing: 8) {
                    ZStack {
                        // Background glow for visibility
                        CustomAnchorIcon()
                            .frame(width: 64, height: 64)
                            .opacity(0.3)
                            .blur(radius: 8)

                        // Main anchor icon with better contrast
                        CustomAnchorIcon()
                            .frame(width: 60, height: 60)
                            .shadow(color: .seaGreen, radius: 4, x: 0, y: 2)
                    }
                    
                    Text("Anchor")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.anchorSilver)
                }
                
                // Main action button - Clean and prominent
                Button(action: {
                    crisisManager.initiateCrisisProtocol()
                }) {
                    Text(crisisManager.isCrisisMode ? "Storm Active" : "Drop Anchor")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 50)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(crisisManager.isCrisisMode ? 
                                    LinearGradient(
                                        colors: [Color.stormGray, Color.stormGray],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) : 
                                    LinearGradient(
                                        colors: [Color.seaGreen, Color.oceanBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.seaGreen.opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                }
                .disabled(crisisManager.isCrisisMode)
            }
            
            Spacer()
            
            // Status indicator - minimal
            if crisisManager.isCrisisMode {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Anchor deployed - riding the storm")
                        .font(.system(size: 14))
                        .foregroundColor(.seafoam)
                }
                .padding(.bottom, 30)
            }
            
        }
    }
}

// MARK: - Friend Circle View
struct FriendCircleView: View {
    let friend: User
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: friend.isOnline ? [.green, .mint] : [.gray, .gray.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: friend.profileImage)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                // Online indicator
                if friend.isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 1.5)
                        )
                        .offset(x: 15, y: -15)
                }
            }
            
            Text(friend.name.components(separatedBy: " ").first ?? friend.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.anchorSilver)
                .lineLimit(1)
        }
    }
}

// MARK: - Bubble Friends View
struct FloatingFriendsView: View {
    let friends: [User]
    @State private var bubblePositions: [CGPoint] = []
    @State private var bubbleOffsets: [CGSize] = []
    @State private var bubbleScales: [Double] = []
    @State private var bubbleOpacities: [Double] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                    FriendCircleView(friend: friend)
                        .scaleEffect(bubbleScales.indices.contains(index) ? bubbleScales[index] : 1.0)
                        .opacity(bubbleOpacities.indices.contains(index) ? bubbleOpacities[index] : 1.0)
                        .position(
                            x: bubblePositions.indices.contains(index) ? bubblePositions[index].x : CGFloat.random(in: 0...geometry.size.width),
                            y: bubblePositions.indices.contains(index) ? bubblePositions[index].y : CGFloat.random(in: 0...geometry.size.height)
                        )
                        .offset(bubbleOffsets.indices.contains(index) ? bubbleOffsets[index] : .zero)
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...8))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...3)),
                            value: bubbleOffsets.indices.contains(index) ? bubbleOffsets[index] : .zero
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...5))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: bubbleScales.indices.contains(index) ? bubbleScales[index] : 1.0
                        )
                }
            }
        }
        .frame(height: 300)
        .onAppear {
            startBubbleAnimation()
        }
    }
    
    private func startBubbleAnimation() {
        bubblePositions = friends.map { _ in
            CGPoint(
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...600)
            )
        }
        
        bubbleOffsets = friends.map { _ in
            CGSize(
                width: CGFloat.random(in: -30 ... 30),
                height: CGFloat.random(in: -50 ... -20) // Always float upward
            )
        }
        
        bubbleScales = friends.map { _ in
            Double.random(in: 0.8...1.2)
        }
        
        bubbleOpacities = friends.map { _ in
            Double.random(in: 0.6...0.9)
        }
        
        // Start random floating off screen
        startRandomFloatOff()
    }
    
    private func startRandomFloatOff() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 5...15), repeats: true) { _ in
            let randomIndex = Int.random(in: 0..<friends.count)
            
            // Make bubble float off screen
            DispatchQueue.main.async {
                bubbleOffsets[randomIndex] = CGSize(
                    width: CGFloat.random(in: -100 ... 100),
                    height: CGFloat.random(in: -200 ... -100)
                )
                bubbleOpacities[randomIndex] = 0.0
                
                // Reset after floating off
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    bubblePositions[randomIndex] = CGPoint(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...600)
                    )
                    bubbleOffsets[randomIndex] = CGSize(
                        width: CGFloat.random(in: -30 ... 30),
                        height: CGFloat.random(in: -50 ... -20)
                    )
                    bubbleOpacities[randomIndex] = Double.random(in: 0.6...0.9)
                }
            }
        }
    }
}

// MARK: - Logo Showcase View
struct LogoShowcaseView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Underwater background
                LinearGradient(
                    colors: [.blue.opacity(0.8), .cyan.opacity(0.6), .teal.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 50) {
                    Spacer()
                    
                    // Large animated logo
                    AnimatedLogoView(size: 250)
                        .scaleEffect(1.1)
                    
                    // App description
                    VStack(spacing: 20) {
                        Text("GROUNDED")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                        
                        Text("Your Anchor in Crisis")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Text("AI-powered crisis intervention through AR visualization")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // Logo variations
                    VStack(spacing: 30) {
                        Text("Logo Variations")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        HStack(spacing: 40) {
                            // Medium static logo
                            AppLogoView(size: 120, showGlow: true)
                            
                            // Small compact logo
                            CompactLogoView(size: 80, showGlow: false)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Special Request Views (Now handled as overlays in CameraView)

#Preview {
    ContentView()
}