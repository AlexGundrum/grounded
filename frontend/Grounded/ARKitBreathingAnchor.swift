//
//  ARKitBreathingAnchor.swift
//  Anchor
//
//  Created by Kori Russell on 9/26/25.
//

import SwiftUI
import ARKit
import SceneKit
import CoreHaptics

// MARK: - ARKit Breathing Anchor SwiftUI Wrapper
struct ARKitBreathingAnchor: View {
    var onSceneViewReady: ((ARSCNView) -> Void)? = nil
    @State private var isActive = false
    @State private var breathingPhase: Double = 0.0
    @State private var currentHeartRate: Double = 75.0 // Default heart rate
    
    // Dynamic breathing cycle configuration based on heart rate
    @State private var inhaleTime: TimeInterval = 4.0
    @State private var holdTime: TimeInterval = 7.0
    @State private var exhaleTime: TimeInterval = 8.0
    @State private var pauseTime: TimeInterval = 1.0
    
    var body: some View {
        ZStack {
            // AR Scene View (Auto-starts breathing)
            ARBreathingSceneView(
                isActive: isActive,
                breathingPhase: breathingPhase,
                inhaleTime: inhaleTime,
                holdTime: holdTime,
                exhaleTime: exhaleTime,
                pauseTime: pauseTime,
                onSceneViewReady: onSceneViewReady
            )
            .ignoresSafeArea()
            .onAppear {
                print("🏆 ARKitBreathingAnchor appeared - Crown jewel is loading!")
                // Auto-start breathing animation immediately
                print("🏆 Starting crown jewel breathing animation with blue bubbles!")
                startBreathing()
            }
            
            // Minimal breathing instruction (no control button)
            VStack {
                Spacer()
                
                if isActive {
                    BreathingInstructionText(breathingPhase: breathingPhase)
                        .padding(.bottom, 100)
                }
            }
        }
    }
    
    private func toggleBreathing() {
        if isActive {
            stopBreathing()
        } else {
            startBreathing()
        }
    }
    
    private func startBreathing() {
        print("🏆 Crown jewel breathing started!")
        isActive = true
        breathingPhase = 0.0
        
        // Start the breathing animation loop
        withAnimation(.easeInOut(duration: inhaleTime + holdTime + exhaleTime + pauseTime).repeatForever(autoreverses: false)) {
            breathingPhase = 1.0
        }
        print("🏆 Breathing animation loop started with blue bubbles!")
    }
    
    private func stopBreathing() {
        isActive = false
        
        // Stop animation smoothly
        withAnimation(.easeOut(duration: 1.0)) {
            breathingPhase = 0.0
        }
    }
}

// MARK: - AR Breathing Scene View
struct ARBreathingSceneView: UIViewRepresentable {
    let isActive: Bool
    let breathingPhase: Double
    let inhaleTime: TimeInterval
    let holdTime: TimeInterval
    let exhaleTime: TimeInterval
    let pauseTime: TimeInterval
    var onSceneViewReady: ((ARSCNView) -> Void)? = nil
    
    func makeUIView(context: Context) -> ARSCNView {
        print("🏆 Creating ARSCNView for crown jewel AR orb!")
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.showsStatistics = false
        sceneView.debugOptions = []
        
        // Keep debug options minimal to avoid interfering with orb visibility
        sceneView.debugOptions = []
        
        // Set scene view reference in coordinator
        context.coordinator.setSceneView(sceneView)
        
        // Create a new scene
        let scene = SCNScene()
        sceneView.scene = scene
        print("🏆 3D scene created for ocean orb")
        
        // Add lighting
        setupLighting(scene: scene)
        
        // Add the ocean breathing orb immediately to verify AR is working
        let oceanOrb = SCNSphere(radius: 0.08)
        let oceanMaterial = SCNMaterial()
        oceanMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        oceanMaterial.emission.contents = UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 0.3)
        oceanOrb.materials = [oceanMaterial]
        
        let oceanNode = SCNNode(geometry: oceanOrb)
        oceanNode.position = SCNVector3(0, 0, -1.5) // In front of camera
        scene.rootNode.addChildNode(oceanNode)
        print("🏆 Added ocean breathing orb immediately to verify AR is working")
        
        // Add simple breathing animation to the orb
        let breatheUp = SCNAction.scale(to: 1.3, duration: 4.0)
        let breatheDown = SCNAction.scale(to: 1.0, duration: 4.0)
        let breatheSequence = SCNAction.sequence([breatheUp, breatheDown])
        let breatheRepeat = SCNAction.repeatForever(breatheSequence)
        oceanNode.runAction(breatheRepeat)
        print("🏆 Started breathing animation on ocean orb")
        
        // Start AR session
        startARSession(sceneView: sceneView)
        print("🏆 AR session started for crown jewel")
        
        // Notify when ready so external systems can attach content (e.g., AR3D pings)
        onSceneViewReady?(sceneView)
        
        return sceneView
    }
    
    func updateUIView(_ sceneView: ARSCNView, context: Context) {
        context.coordinator.updateBreathingState(
            isActive: isActive,
            breathingPhase: breathingPhase,
            inhaleTime: inhaleTime,
            holdTime: holdTime,
            exhaleTime: exhaleTime,
            pauseTime: pauseTime
        )
    }
    
    static func dismantleUIView(_ sceneView: ARSCNView, coordinator: ARBreathingCoordinator) {
        // Properly pause AR session to prevent memory leaks
        sceneView.session.pause()
    }
    
    private func setupLighting(scene: SCNScene) {
        // Ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white.withAlphaComponent(0.3)
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Directional light
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 800
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(0, 5, 5)
        directionalLightNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLightNode)
    }
    
    private func startARSession(sceneView: ARSCNView) {
        print("Starting AR session for crown jewel")
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        // Advanced AR settings for impressive visuals
        if #available(iOS 13.0, *) {
            configuration.environmentTexturing = .automatic
        }
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        }
        
        // Check if AR is supported
        guard ARWorldTrackingConfiguration.isSupported else {
            print("AR World Tracking not supported on this device")
            return
        }
        
        sceneView.session.run(configuration)
        print("AR session started successfully with advanced settings")
    }
    
    func makeCoordinator() -> ARBreathingCoordinator {
        ARBreathingCoordinator()
    }
}

// MARK: - AR Breathing Coordinator
class ARBreathingCoordinator: NSObject, ARSCNViewDelegate {
    private var breathingNode: SCNNode?
    private var isBreathingActive = false
    private var breathingPhase: Double = 0.0
    private var inhaleTime: TimeInterval = 4.0
    private var holdTime: TimeInterval = 7.0
    private var exhaleTime: TimeInterval = 8.0
    private var pauseTime: TimeInterval = 1.0
    
    // Haptic feedback system
    private var hapticEngine: CHHapticEngine?
    private var breathingHapticPattern: CHHapticPattern?
    
    // Heart rate monitoring
    private var currentHeartRate: Double = 75.0
    private var heartRateTimer: Timer?
    
    override init() {
        super.init()
        setupHapticEngine()
        startHeartRateMonitoring()
    }
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Haptic feedback not supported on this device")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            createBreathingHapticPattern()
            print("✅ Haptic engine initialized for breathing")
        } catch {
            print("❌ Failed to initialize haptic engine: \(error)")
        }
    }
    
    private func createBreathingHapticPattern() {
        guard hapticEngine != nil else { return }
        
        var events: [CHHapticEvent] = []
        
        // Inhale: gentle increasing intensity
        for i in 0..<10 {
            let time = TimeInterval(i) * (inhaleTime / 10.0)
            let intensity = Float(0.3 + (Double(i) / 10.0) * 0.4) // 0.3 to 0.7
            let sharpness = Float(0.2)
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: time,
                duration: inhaleTime / 10.0
            )
            events.append(event)
        }
        
        // Hold: steady gentle pulse
        let holdEvent = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ],
            relativeTime: inhaleTime,
            duration: holdTime
        )
        events.append(holdEvent)
        
        // Exhale: gentle decreasing intensity
        for i in 0..<12 {
            let time = inhaleTime + holdTime + TimeInterval(i) * (exhaleTime / 12.0)
            let intensity = Float(0.7 - (Double(i) / 12.0) * 0.6) // 0.7 to 0.1
            let sharpness = Float(0.1)
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: time,
                duration: exhaleTime / 12.0
            )
            events.append(event)
        }
        
        do {
            breathingHapticPattern = try CHHapticPattern(events: events, parameters: [])
            print("✅ Breathing haptic pattern created")
        } catch {
            print("❌ Failed to create haptic pattern: \(error)")
        }
    }
    
    private func startHeartRateMonitoring() {
        // Simulate heart rate monitoring (in production, integrate with HealthKit)
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Simulate realistic heart rate fluctuation (60-100 BPM)
            let variation = Double.random(in: -3...3)
            self.currentHeartRate = max(60, min(100, self.currentHeartRate + variation))
            
            // Adjust breathing timing based on heart rate
            self.updateBreathingTimingForHeartRate()
        }
    }
    
    private func updateBreathingTimingForHeartRate() {
        // Calculate optimal breathing rate based on heart rate
        // Higher heart rate = slower breathing to promote calming
        let baseHeartRate = 75.0
        let heartRateDelta = currentHeartRate - baseHeartRate
        
        // Adjust breathing times (slower breathing for higher heart rate)
        let adjustment = heartRateDelta / 20.0 // Scale factor
        
        inhaleTime = max(3.0, min(6.0, 4.0 + adjustment))
        holdTime = max(5.0, min(9.0, 7.0 + adjustment))
        exhaleTime = max(6.0, min(10.0, 8.0 + adjustment))
        pauseTime = max(0.5, min(2.0, 1.0 + adjustment * 0.5))
        
        print("💓 Heart Rate: \(Int(currentHeartRate)) BPM → Breathing: \(String(format: "%.1f", inhaleTime))-\(String(format: "%.1f", holdTime))-\(String(format: "%.1f", exhaleTime))")
        
        // Recreate haptic pattern with new timing
        createBreathingHapticPattern()
    }
    
    func updateBreathingState(
        isActive: Bool,
        breathingPhase: Double,
        inhaleTime: TimeInterval,
        holdTime: TimeInterval,
        exhaleTime: TimeInterval,
        pauseTime: TimeInterval
    ) {
        print("🏆 updateBreathingState called - isActive: \(isActive), breathingNode exists: \(breathingNode != nil)")
        self.isBreathingActive = isActive
        self.breathingPhase = breathingPhase
        self.inhaleTime = inhaleTime
        self.holdTime = holdTime
        self.exhaleTime = exhaleTime
        self.pauseTime = pauseTime
        
        if isActive && breathingNode == nil {
            print("🏆 Creating breathing visualization for crown jewel!")
            createBreathingVisualization()
            startHapticFeedback()
        } else if !isActive {
            print("🛑 Stopping breathing visualization")
            stopBreathing()
            stopHapticFeedback()
        } else {
            print("🏆 Breathing active but node already exists - updating animation")
            // Update existing animation if needed
            if breathingNode != nil {
                print("🏆 Node exists, animation should already be running")
            }
        }
    }
    
    private func createBreathingVisualization() {
        guard let sceneView = getSceneView() else { 
            print("❌ No scene view available for crown jewel")
            return 
        }
        
        print("🏆 Creating crown jewel ocean orb with blue bubbles!")
        // Create Apple Health-style breathing sphere
        let breathingGeometry = createBreathingGeometry()
        breathingNode = SCNNode(geometry: breathingGeometry)
        
        // Position the node in front of the camera
        breathingNode?.position = SCNVector3(0, 0, -1.5)
        
        // Add dynamic water splash particle system
        print("🌊 Adding water splash particle system with blue bubbles!")
        let waterSplashSystem = createWaterSplashSystem()
        breathingNode?.addParticleSystem(waterSplashSystem)
        
        // Add underwater caustics effect
        print("✨ Adding underwater caustics effect!")
        addUnderwaterCaustics(to: breathingNode!)
        
        // Add inner water flow
        print("💧 Adding inner water flow!")
        addInnerWaterFlow(to: breathingNode!)
        
        // Add the node to the scene
        sceneView.scene.rootNode.addChildNode(breathingNode!)
        print("🏆 Crown jewel ocean orb added to 3D scene!")
        
        // Start breathing animation
        startBreathingCycle()
    }
    
    private func addBreathingParticles() {
        guard let breathingNode = breathingNode else { return }
        
        // Create Apple Health-style particle system
        let particleSystem = SCNParticleSystem()
        
        // Particle appearance
        particleSystem.particleImage = createParticleTexture()
        particleSystem.particleSize = 0.008
        particleSystem.particleSizeVariation = 0.003
        
        // Emission properties
        particleSystem.birthRate = 15
        particleSystem.particleLifeSpan = 3.0
        particleSystem.particleLifeSpanVariation = 1.0
        
        // Movement (gentle floating outward) - using correct SCNParticleSystem properties
        particleSystem.emitterShape = SCNSphere(radius: 0.05)
        particleSystem.particleVelocity = 0.02
        particleSystem.particleVelocityVariation = 0.01
        particleSystem.acceleration = SCNVector3(0, 0.005, 0) // Slight upward float
        
        // Ocean-themed particle colors (deep blues and sea greens)
        particleSystem.particleColor = UIColor(red: 0.15, green: 0.45, blue: 0.85, alpha: 0.9)
        particleSystem.particleColorVariation = SCNVector4(0.1, 0.2, 0.15, 0.2)
        
        // Transparency fade using correct keyframe animation
        let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
        fadeAnimation.values = [0.8, 0.6, 0.3, 0.0]
        fadeAnimation.keyTimes = [0.0, 0.3, 0.7, 1.0]
        let fadeController = SCNParticlePropertyController(animation: fadeAnimation)
        
        // Scale animation using correct keyframe animation
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [0.3, 1.0, 1.2, 0.8]
        scaleAnimation.keyTimes = [0.0, 0.2, 0.6, 1.0]
        let scaleController = SCNParticlePropertyController(animation: scaleAnimation)
        
        // Apply property controllers with correct property names
        particleSystem.propertyControllers = [
            SCNParticleSystem.ParticleProperty.opacity: fadeController,
            SCNParticleSystem.ParticleProperty.size: scaleController
        ]
        
        // Blending for soft particle effect
        particleSystem.blendMode = .additive
        particleSystem.isLightingEnabled = false
        
        // Attach to breathing node
        breathingNode.addParticleSystem(particleSystem)
    }
    
    private func createParticleTexture() -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create soft circular red particle
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 4
            
            let colors = [
                UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0).cgColor,
                UIColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.7).cgColor,
                UIColor.clear.cgColor
            ]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.7, 1.0])!
            
            cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        }
    }
    
    private func createBreathingGeometry() -> SCNGeometry {
        // Create simple, clean ocean orb - even smaller and cleaner
        let oceanOrb = SCNSphere(radius: 0.08)
        
        // Use just one clean material to avoid artifacts
        let cleanMaterial = createCleanOceanMaterial()
        
        oceanOrb.materials = [cleanMaterial]
        
        return oceanOrb
    }
    
    private func createCleanOceanMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        
        // Simple, clean ocean blue color
        material.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        
        // Gentle ocean glow
        material.emission.contents = UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 0.3)
        
        // Clean, solid appearance
        material.transparency = 1.0
        material.metalness.contents = 0.2
        material.roughness.contents = 0.3
        
        // Single-sided for clean appearance
        material.isDoubleSided = false
        
        return material
    }
    
    private func createAdvancedOceanMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        
        // Deep ocean blue with animated gradient texture
        material.diffuse.contents = createAnimatedOceanTexture()
        
        // Ocean blue emission for calming glow with caustics
        material.emission.contents = createCausticsEmissionTexture()
        
        // Ocean-like properties - beautiful but solid appearance
        material.transparency = 0.95
        material.metalness.contents = 0.6
        material.roughness.contents = 0.2
        
        // Advanced water effects
        material.normal.contents = createWaterNormalMap()
        material.fresnelExponent = 1.5
        
        // Double-sided for full visibility with holes
        material.isDoubleSided = true
        material.cullMode = .back
        
        // Add animated properties for water movement
        addWaterAnimation(to: material)
        
        return material
    }
    
    private func createAnimatedOceanTexture() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create beautiful ocean orb with depth and dimension
            let center = CGPoint(x: size.width/2, y: size.height/2)
            
            // Main ocean gradient from center outward
            let mainColors = [
                UIColor(red: 0.8, green: 0.95, blue: 1.0, alpha: 1.0).cgColor,  // Bright center (like light hitting water)
                UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 0.9).cgColor,   // Ocean surface
                UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.8).cgColor,   // Mid ocean
                UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 0.7).cgColor,   // Deep ocean
                UIColor(red: 0.05, green: 0.2, blue: 0.4, alpha: 0.6).cgColor   // Ocean depths
            ]
            
            let mainGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: mainColors as CFArray, locations: [0.0, 0.3, 0.6, 0.8, 1.0])!
            
            // Draw main spherical gradient
            cgContext.drawRadialGradient(mainGradient,
                                       startCenter: center,
                                       startRadius: 0,
                                       endCenter: center,
                                       endRadius: size.width/2,
                                       options: [])
            
            // Add ocean surface highlights
            let highlightColors = [
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8).cgColor,
                UIColor.clear.cgColor
            ]
            
            let highlightGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: highlightColors as CFArray, locations: [0.0, 1.0])!
            
            // Add multiple highlight spots for realistic water surface
            for i in 0..<8 {
                let angle = Double(i) * Double.pi / 4
                let radius = size.width * 0.25
                let highlightX = center.x + cos(angle) * radius
                let highlightY = center.y + sin(angle) * radius
                
                cgContext.drawRadialGradient(highlightGradient,
                                           startCenter: CGPoint(x: highlightX, y: highlightY),
                                           startRadius: 0,
                                           endCenter: CGPoint(x: highlightX, y: highlightY),
                                           endRadius: 30,
                                           options: [])
            }
            
            // Add central bright spot for depth
            let centerHighlight = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6).cgColor,
                UIColor.clear.cgColor
            ] as CFArray, locations: [0.0, 1.0])!
            
            cgContext.drawRadialGradient(centerHighlight,
                                       startCenter: center,
                                       startRadius: 0,
                                       endCenter: center,
                                       endRadius: 60,
                                       options: [])
        }
    }
    
    private func createCausticsEmissionTexture() -> UIImage {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create beautiful glowing orb emission
            let center = CGPoint(x: size.width/2, y: size.height/2)
            
            // Main emission gradient - bright center fading outward
            let emissionColors = [
                UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0).cgColor,  // Bright center
                UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 0.8).cgColor,   // Strong glow
                UIColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 0.6).cgColor,   // Mid glow
                UIColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 0.3).cgColor,   // Outer glow
                UIColor.clear.cgColor
            ]
            
            let emissionGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: emissionColors as CFArray, locations: [0.0, 0.2, 0.5, 0.8, 1.0])!
            
            // Draw main emission
            cgContext.drawRadialGradient(emissionGradient,
                                       startCenter: center,
                                       startRadius: 0,
                                       endCenter: center,
                                       endRadius: size.width/2,
                                       options: [])
            
            // Add sparkling highlights for magical effect
            let sparkleColors = [
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9).cgColor,
                UIColor.clear.cgColor
            ]
            
            let sparkleGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: sparkleColors as CFArray, locations: [0.0, 1.0])!
            
            // Add sparkles around the orb
            for i in 0..<16 {
                let angle = Double(i) * Double.pi / 8
                let radius = Double.random(in: 40...80)
                let sparkleX = center.x + cos(angle) * radius
                let sparkleY = center.y + sin(angle) * radius
                let sparkleSize = CGFloat.random(in: 8...20)
                
                cgContext.drawRadialGradient(sparkleGradient,
                                           startCenter: CGPoint(x: sparkleX, y: sparkleY),
                                           startRadius: 0,
                                           endCenter: CGPoint(x: sparkleX, y: sparkleY),
                                           endRadius: sparkleSize,
                                           options: [])
            }
        }
    }
    
    private func createWaterNormalMap() -> UIImage {
        let size = CGSize(width: 128, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create water surface normal map for realistic water distortion
            for y in stride(from: 0, to: Int(size.height), by: 4) {
                for x in stride(from: 0, to: Int(size.width), by: 4) {
                    let wave1 = sin(Double(x) * 0.1) * 0.5
                    let wave2 = cos(Double(y) * 0.08) * 0.3
                    let combined = wave1 + wave2
                    
                    let intensity = CGFloat(combined * 0.5 + 0.5)
                    let color = UIColor(red: 0.5 + intensity * 0.5, green: 0.5, blue: 1.0, alpha: 1.0)
                    
                    color.setFill()
                    cgContext.fill(CGRect(x: x, y: y, width: 4, height: 4))
                }
            }
        }
    }
    
    private func addWaterAnimation(to material: SCNMaterial) {
        // Animate the normal map for water movement
        let animation = CABasicAnimation(keyPath: "contentsTransform.translation.x")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 4.0
        animation.repeatCount = .infinity
        
        material.normal.contents = createWaterNormalMap()
        material.normal.addAnimation(animation, forKey: "waterMovement")
    }
    
    // MARK: - Water Splash Effects
    private func createWaterSplashSystem() -> SCNParticleSystem {
        let splashSystem = SCNParticleSystem()
        
        // Water droplet appearance
        splashSystem.particleImage = createWaterDropletTexture()
        splashSystem.particleSize = 0.015
        splashSystem.particleSizeVariation = 0.008
        
        // Emission from the surface of the orb
        splashSystem.emitterShape = SCNSphere(radius: 0.08)
        splashSystem.birthRate = 25
        splashSystem.particleLifeSpan = 2.5
        splashSystem.particleLifeSpanVariation = 1.0
        
        // Water droplet physics
        splashSystem.particleVelocity = 0.15
        splashSystem.particleVelocityVariation = 0.08
        splashSystem.acceleration = SCNVector3(0, -0.02, 0) // Gravity
        
        // Beautiful blue water colors
        splashSystem.particleColor = UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.9)
        splashSystem.particleColorVariation = SCNVector4(0.1, 0.2, 0.2, 0.2)
        
        // Water droplet transparency and scale animation
        let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
        fadeAnimation.values = [0.0, 1.0, 0.8, 0.0]
        fadeAnimation.keyTimes = [0.0, 0.1, 0.7, 1.0]
        let fadeController = SCNParticlePropertyController(animation: fadeAnimation)
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [0.2, 1.0, 1.2, 0.5]
        scaleAnimation.keyTimes = [0.0, 0.2, 0.6, 1.0]
        let scaleController = SCNParticlePropertyController(animation: scaleAnimation)
        
        splashSystem.propertyControllers = [
            SCNParticleSystem.ParticleProperty.opacity: fadeController,
            SCNParticleSystem.ParticleProperty.size: scaleController
        ]
        
        // Water-like blending
        splashSystem.blendMode = .alpha
        splashSystem.isLightingEnabled = true
        
        return splashSystem
    }
    
    private func createWaterDropletTexture() -> UIImage {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create water droplet shape
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 3
            
            let colors = [
                UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0).cgColor,
                UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.8).cgColor,
                UIColor.clear.cgColor
            ]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.6, 1.0])!
            
            cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        }
    }
    
    
    // MARK: - Underwater Caustics
    private func addUnderwaterCaustics(to node: SCNNode) {
        // Create caustic light projection
        let causticsLight = SCNLight()
        causticsLight.type = .spot
        causticsLight.color = UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0)
        causticsLight.intensity = 300
        causticsLight.spotInnerAngle = 45
        causticsLight.spotOuterAngle = 60
        
        let causticsNode = SCNNode()
        causticsNode.light = causticsLight
        causticsNode.position = SCNVector3(0, 1, 1)
        causticsNode.look(at: SCNVector3(0, 0, 0))
        
        // Animate caustic movement
        let causticsAnimation = SCNAction.repeatForever(
            SCNAction.sequence([
                SCNAction.moveBy(x: 0.3, y: 0.2, z: 0.1, duration: 3.0),
                SCNAction.moveBy(x: -0.3, y: -0.2, z: -0.1, duration: 3.0)
            ])
        )
        causticsNode.runAction(causticsAnimation)
        
        node.addChildNode(causticsNode)
    }
    
    // MARK: - Inner Water Flow
    private func addInnerWaterFlow(to node: SCNNode) {
        // Create inner water flow particle system
        let flowSystem = SCNParticleSystem()
        
        flowSystem.particleImage = createWaterFlowTexture()
        flowSystem.particleSize = 0.008
        flowSystem.particleSizeVariation = 0.004
        
        // Gentle flow around the orb surface
        flowSystem.emitterShape = SCNSphere(radius: 0.06)
        flowSystem.birthRate = 20
        flowSystem.particleLifeSpan = 4.0
        flowSystem.particleLifeSpanVariation = 1.5
        
        // Circular motion
        flowSystem.particleVelocity = 0.08
        flowSystem.particleVelocityVariation = 0.04
        flowSystem.acceleration = SCNVector3(0, 0.005, 0)
        
        // Inner water colors (beautiful blue, more transparent)
        flowSystem.particleColor = UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 0.6)
        flowSystem.particleColorVariation = SCNVector4(0.1, 0.15, 0.2, 0.2)
        
        // Flowing water animation
        let flowAnimation = CAKeyframeAnimation(keyPath: "opacity")
        flowAnimation.values = [0.0, 0.8, 0.6, 0.0]
        flowAnimation.keyTimes = [0.0, 0.2, 0.7, 1.0]
        let flowController = SCNParticlePropertyController(animation: flowAnimation)
        
        flowSystem.propertyControllers = [
            SCNParticleSystem.ParticleProperty.opacity: flowController
        ]
        
        flowSystem.blendMode = .additive
        flowSystem.isLightingEnabled = false
        
        node.addParticleSystem(flowSystem)
    }
    
    private func createWaterFlowTexture() -> UIImage {
        let size = CGSize(width: 16, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create flowing water streak
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let colors = [
                UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.8).cgColor,
                UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 0.6).cgColor,
                UIColor.clear.cgColor
            ]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.5, 1.0])!
            
            // Elliptical shape for flowing water
            let ellipseRect = CGRect(x: 2, y: 6, width: 12, height: 4)
            cgContext.addEllipse(in: ellipseRect)
            cgContext.clip()
            
            cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 8, options: [])
        }
    }
    
    private func createOceanOrbMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        
        // Deep ocean blue with gradient texture
        material.diffuse.contents = createOceanGradientTexture()
        
        // Ocean blue emission for calming glow
        material.emission.contents = createOceanEmissionTexture()
        
        // Ocean-like properties - slightly reflective like water
        material.transparency = 0.95
        material.metalness.contents = 0.4
        material.roughness.contents = 0.3
        
        // Fresnel effect for water-like appearance
        material.fresnelExponent = 2.0
        
        // Double-sided for full visibility
        material.isDoubleSided = true
        material.cullMode = .back
        
        return material
    }
    
    private func createInnerOceanGlow() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        material.emission.contents = createInnerOceanGlowTexture()
        material.transparency = 0.7
        material.blendMode = .add
        return material
    }
    
    private func createOceanRim() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = createOceanRimTexture()
        material.metalness.contents = 0.8
        material.roughness.contents = 0.2
        material.transparency = 0.8
        return material
    }
    
    private func createHeartRedGradient() -> UIImage {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create warm red gradient for emotional heart
            let colors = [
                UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0).cgColor,  // Bright warm red center
                UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.9).cgColor,   // Deep red middle
                UIColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 0.7).cgColor    // Dark red edge
            ]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.5, 1.0])!
            
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            
            cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        }
    }
    
    private func createHeartRedEmission() -> UIImage {
        let size = CGSize(width: 128, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Soft red emission for heartbeat glow
            let colors = [
                UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.6).cgColor,  // Bright center
                UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 0.3).cgColor,  // Mid glow
                UIColor.clear.cgColor  // Transparent edge
            ]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.6, 1.0])!
            
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            
            cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        }
    }
    
    private func createInnerGlowMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        material.emission.contents = createInnerGlowTexture()
        material.transparency = 0.6
        material.blendMode = .add
        return material
    }
    
    private func createOuterRimMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = createRimTexture()
        material.metalness.contents = 0.9
        material.roughness.contents = 0.1
        material.transparency = 0.7
        return material
    }
    
    private func createOceanGradientTexture() -> UIImage {
        let size = CGSize(width: 256, height: 256)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Deep ocean gradient - from abyss to surface
        let colors = [
            UIColor(red: 0.02, green: 0.08, blue: 0.20, alpha: 1.0).cgColor, // Deep abyss
            UIColor(red: 0.05, green: 0.15, blue: 0.35, alpha: 1.0).cgColor, // Deep ocean
            UIColor(red: 0.10, green: 0.30, blue: 0.55, alpha: 1.0).cgColor, // Ocean blue
            UIColor(red: 0.15, green: 0.45, blue: 0.65, alpha: 1.0).cgColor, // Mid ocean
            UIColor(red: 0.20, green: 0.55, blue: 0.75, alpha: 1.0).cgColor, // Surface blue
            UIColor(red: 0.15, green: 0.45, blue: 0.50, alpha: 1.0).cgColor  // Sea green
        ]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.2, 0.4, 0.6, 0.8, 1.0])!
        
        context.drawRadialGradient(gradient,
                                 startCenter: CGPoint(x: size.width/2, y: size.height/2),
                                 startRadius: size.width/6,
                                 endCenter: CGPoint(x: size.width/2, y: size.height/2),
                                 endRadius: size.width/2,
                                 options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createOceanEmissionTexture() -> UIImage {
        let size = CGSize(width: 128, height: 128)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 0.8).cgColor,  // Bright ocean blue
            UIColor(red: 0.2, green: 0.5, blue: 0.7, alpha: 0.5).cgColor,  // Mid glow
            UIColor(red: 0.1, green: 0.3, blue: 0.5, alpha: 0.2).cgColor,  // Outer glow
            UIColor.clear.cgColor
        ]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.4, 0.7, 1.0])!
        
        context.drawRadialGradient(gradient,
                                 startCenter: CGPoint(x: size.width/2, y: size.height/2),
                                 startRadius: 0,
                                 endCenter: CGPoint(x: size.width/2, y: size.height/2),
                                 endRadius: size.width/2,
                                 options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createInnerOceanGlowTexture() -> UIImage {
        let size = CGSize(width: 128, height: 128)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let center = CGPoint(x: size.width/2, y: size.height/2)
        
        // Create magical inner glow with multiple layers
        let innerColors = [
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor,  // Bright white center
            UIColor(red: 0.8, green: 0.95, blue: 1.0, alpha: 0.9).cgColor,  // Soft blue-white
            UIColor(red: 0.6, green: 0.8, blue: 0.95, alpha: 0.7).cgColor,  // Ocean blue
            UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 0.5).cgColor,   // Deeper blue
            UIColor.clear.cgColor
        ]
        let innerGradient = CGGradient(colorsSpace: colorSpace, colors: innerColors as CFArray, locations: [0.0, 0.2, 0.5, 0.8, 1.0])!
        
        // Draw main inner glow
        context.drawRadialGradient(innerGradient,
                                 startCenter: center,
                                 startRadius: 0,
                                 endCenter: center,
                                 endRadius: size.width/2,
                                 options: [])
        
        // Add pulsing energy rings
        for i in 0..<3 {
            let ringRadius = CGFloat(15 + i * 8)
            let ringColors = [
                UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.6).cgColor,
                UIColor.clear.cgColor
            ]
            let ringGradient = CGGradient(colorsSpace: colorSpace, colors: ringColors as CFArray, locations: [0.0, 1.0])!
            
            context.drawRadialGradient(ringGradient,
                                     startCenter: center,
                                     startRadius: ringRadius - 2,
                                     endCenter: center,
                                     endRadius: ringRadius + 2,
                                     options: [])
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createOceanRimTexture() -> UIImage {
        let size = CGSize(width: 128, height: 128)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        let center = CGPoint(x: size.width/2, y: size.height/2)
        
        // Create beautiful rim with depth and highlights
        let rimColors = [
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9).cgColor,  // Bright rim highlight
            UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.8).cgColor,  // Soft rim
            UIColor(red: 0.6, green: 0.8, blue: 0.95, alpha: 0.6).cgColor, // Mid rim
            UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 0.4).cgColor,  // Deep rim
            UIColor.clear.cgColor
        ]
        
        let rimGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: rimColors as CFArray, locations: [0.0, 0.3, 0.6, 0.9, 1.0])!
        
        // Draw main rim
        context.drawRadialGradient(rimGradient,
                                 startCenter: center,
                                 startRadius: size.width * 0.35,
                                 endCenter: center,
                                 endRadius: size.width/2,
                                 options: [])
        
        // Add rim sparkles for magical effect
        let sparkleColors = [
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor,
            UIColor.clear.cgColor
        ]
        let sparkleGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: sparkleColors as CFArray, locations: [0.0, 1.0])!
        
        // Add sparkles around the rim
        for i in 0..<12 {
            let angle = Double(i) * Double.pi / 6
            let radius = size.width * 0.42
            let sparkleX = center.x + cos(angle) * radius
            let sparkleY = center.y + sin(angle) * radius
            let sparkleSize = CGFloat.random(in: 4...12)
            
            context.drawRadialGradient(sparkleGradient,
                                     startCenter: CGPoint(x: sparkleX, y: sparkleY),
                                     startRadius: 0,
                                     endCenter: CGPoint(x: sparkleX, y: sparkleY),
                                     endRadius: sparkleSize,
                                     options: [])
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createEmissionTexture() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.8).cgColor,
            UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 0.4).cgColor,
            UIColor.clear.cgColor
        ]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.6, 1.0])!
        
        context.drawRadialGradient(gradient,
                                 startCenter: CGPoint(x: size.width/2, y: size.height/2),
                                 startRadius: 0,
                                 endCenter: CGPoint(x: size.width/2, y: size.height/2),
                                 endRadius: size.width/2,
                                 options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createInnerGlowTexture() -> UIImage {
        let size = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9).cgColor,
            UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.6).cgColor,
            UIColor.clear.cgColor
        ]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.4, 1.0])!
        
        context.drawRadialGradient(gradient,
                                 startCenter: CGPoint(x: size.width/2, y: size.height/2),
                                 startRadius: 0,
                                 endCenter: CGPoint(x: size.width/2, y: size.height/2),
                                 endRadius: size.width/3,
                                 options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createRimTexture() -> UIImage {
        let size = CGSize(width: 80, height: 80)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Create a rim lighting effect
        UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0).setFill()
        context.fillEllipse(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func startBreathingCycle() {
        guard isBreathingActive, let node = breathingNode else { return }
        
        // Remove any existing animations to prevent conflicts
        node.removeAction(forKey: "breathing")
        node.removeAction(forKey: "rotation")
        node.removeAction(forKey: "floating")
        node.removeAction(forKey: "heartBeat")
        node.removeAction(forKey: "heartBeatGlow")
        node.removeAction(forKey: "synchronizedWaterEffects")
        
        // Reset to original scale to prevent jumps
        node.scale = SCNVector3(1.0, 1.0, 1.0)
        
        // Create smooth breathing animation with smaller scale changes
        let inhaleScale = SCNVector3(1.3, 1.3, 1.3)  // Smaller scale change for smoother effect
        let originalScale = SCNVector3(1.0, 1.0, 1.0)
        
        // Inhale animation - very smooth
        let inhaleAction = SCNAction.scale(to: CGFloat(inhaleScale.x), duration: inhaleTime)
        inhaleAction.timingMode = .easeInEaseOut
        
        // Hold action
        let holdAction = SCNAction.wait(duration: holdTime)
        
        // Exhale animation - very smooth
        let exhaleAction = SCNAction.scale(to: CGFloat(originalScale.x), duration: exhaleTime)
        exhaleAction.timingMode = .easeInEaseOut
        
        // Pause action
        let pauseAction = SCNAction.wait(duration: pauseTime)
        
        // Combine into sequence with smooth transitions
        let breathingSequence = SCNAction.sequence([
            inhaleAction,
            holdAction,
            exhaleAction,
            pauseAction
        ])
        
        // Repeat forever with smooth transitions
        let repeatAction = SCNAction.repeatForever(breathingSequence)
        
        // Add gentle rotation for visual appeal
        let rotationAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: inhaleTime + holdTime + exhaleTime + pauseTime)
        let repeatRotation = SCNAction.repeatForever(rotationAction)
        
        // Run both animations
        node.runAction(repeatAction, forKey: "breathing")
        node.runAction(repeatRotation, forKey: "rotation")
        
        // Add gentle floating animation
        let floatUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 3.0)  // Slower, gentler
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 3.0)
        floatDown.timingMode = .easeInEaseOut
        let floatSequence = SCNAction.sequence([floatUp, floatDown])
        let repeatFloat = SCNAction.repeatForever(floatSequence)
        node.runAction(repeatFloat, forKey: "floating")
        
        // Add heart rate beating on top of breathing
        startHeartBeatAnimation()
        
        // Add synchronized water effects
        addSynchronizedWaterEffects()
    }
    
    private func startHeartBeatAnimation() {
        guard let node = breathingNode else { return }
        
        // Remove existing heartbeat animation to prevent conflicts
        node.removeAction(forKey: "heartBeat")
        node.removeAction(forKey: "heartBeatGlow")
        
        // Get current heart rate from the simulation  
        let currentBPM = getCurrentHeartRate()
        let beatInterval = 60.0 / currentBPM // Convert BPM to seconds per beat
        
        // Very gentle heartbeat pulse to avoid conflicts with breathing
        let beatScale = SCNVector3(1.05, 1.05, 1.05)  // Much smaller scale change
        let normalScale = SCNVector3(1.0, 1.0, 1.0)
        
        // Smooth beat animation with natural curve
        let beatUpAction = SCNAction.scale(to: CGFloat(beatScale.x), duration: 0.15)  // Faster, smoother
        beatUpAction.timingMode = .easeInEaseOut
        
        let beatDownAction = SCNAction.scale(to: CGFloat(normalScale.x), duration: 0.25)
        beatDownAction.timingMode = .easeInEaseOut
        
        let pauseAction = SCNAction.wait(duration: max(0.3, beatInterval - 0.4))
        
        // Heart beat sequence with smooth transitions
        let heartBeatSequence = SCNAction.sequence([beatUpAction, beatDownAction, pauseAction])
        let repeatHeartBeat = SCNAction.repeatForever(heartBeatSequence)
        
        // Apply heartbeat animation (additive to breathing)
        node.runAction(repeatHeartBeat, forKey: "heartBeat")
        
        // Add subtle glow pulse that matches heartbeat
        addHeartBeatGlow()
    }
    
    private func addHeartBeatGlow() {
        guard let node = breathingNode else { return }
        
        // Get current heart rate for glow timing
        let currentBPM = getCurrentHeartRate()
        let beatInterval = 60.0 / currentBPM
        
        // Ocean depth glow animation
        let brightGlow = UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)  // Bright ocean surface
        let normalGlow = UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 1.0)  // Deep ocean
        
        // Create glow pulse animation
        let glowUpAction = SCNAction.customAction(duration: 0.2) { (node, elapsedTime) in
            let progress = elapsedTime / 0.2
            let interpolatedColor = self.interpolateColor(from: normalGlow, to: brightGlow, progress: Float(progress))
            node.geometry?.materials.first?.emission.contents = interpolatedColor
        }
        
        let glowDownAction = SCNAction.customAction(duration: 0.3) { (node, elapsedTime) in
            let progress = elapsedTime / 0.3
            let interpolatedColor = self.interpolateColor(from: brightGlow, to: normalGlow, progress: Float(progress))
            node.geometry?.materials.first?.emission.contents = interpolatedColor
        }
        
        let pauseAction = SCNAction.wait(duration: max(0.2, beatInterval - 0.5))
        
        let glowSequence = SCNAction.sequence([glowUpAction, glowDownAction, pauseAction])
        let repeatGlow = SCNAction.repeatForever(glowSequence)
        
        node.runAction(repeatGlow, forKey: "heartBeatGlow")
    }
    
    private func addSynchronizedWaterEffects() {
        guard let node = breathingNode else { return }
        
        // Synchronize water splash intensity with breathing cycle
        let splashIntensityAction = SCNAction.repeatForever(
            SCNAction.sequence([
                SCNAction.customAction(duration: inhaleTime) { (node, elapsedTime) in
                    // Increase splash intensity during inhale
                    let progress = Float(elapsedTime / self.inhaleTime)
                    self.updateWaterSplashIntensity(intensity: 0.3 + progress * 0.7)
                },
                SCNAction.customAction(duration: holdTime) { (node, elapsedTime) in
                    // Maintain high intensity during hold
                    self.updateWaterSplashIntensity(intensity: 1.0)
                },
                SCNAction.customAction(duration: exhaleTime) { (node, elapsedTime) in
                    // Decrease splash intensity during exhale
                    let progress = Float(elapsedTime / self.exhaleTime)
                    self.updateWaterSplashIntensity(intensity: 1.0 - progress * 0.8)
                },
                SCNAction.customAction(duration: pauseTime) { (node, elapsedTime) in
                    // Minimal splash during pause
                    self.updateWaterSplashIntensity(intensity: 0.2)
                }
            ])
        )
        
        node.runAction(splashIntensityAction, forKey: "synchronizedWaterEffects")
    }
    
    private func updateWaterSplashIntensity(intensity: Float) {
        // Update particle system birth rate based on breathing phase
        breathingNode?.particleSystems?.forEach { particleSystem in
            particleSystem.birthRate = CGFloat(intensity * 25) // Scale from 0 to 25 particles per second
        }
    }
    
    private func interpolateColor(from: UIColor, to: UIColor, progress: Float) -> UIColor {
        var fromRed: CGFloat = 0, fromGreen: CGFloat = 0, fromBlue: CGFloat = 0, fromAlpha: CGFloat = 0
        var toRed: CGFloat = 0, toGreen: CGFloat = 0, toBlue: CGFloat = 0, toAlpha: CGFloat = 0
        
        from.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        to.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)
        
        let interpolatedRed = fromRed + (toRed - fromRed) * CGFloat(progress)
        let interpolatedGreen = fromGreen + (toGreen - fromGreen) * CGFloat(progress)
        let interpolatedBlue = fromBlue + (toBlue - fromBlue) * CGFloat(progress)
        let interpolatedAlpha = fromAlpha + (toAlpha - fromAlpha) * CGFloat(progress)
        
        return UIColor(red: interpolatedRed, green: interpolatedGreen, blue: interpolatedBlue, alpha: interpolatedAlpha)
    }
    
    private func getCurrentHeartRate() -> Double {
        // Use the simulated heart rate from the heart rate monitoring
        return currentHeartRate
    }
    
    private func startHapticFeedback() {
        guard let hapticEngine = hapticEngine,
              let pattern = breathingHapticPattern else {
            print("⚠️ Haptic feedback not available")
            return
        }
        
        do {
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
            // Schedule repeating haptic pattern
            Timer.scheduledTimer(withTimeInterval: inhaleTime + holdTime + exhaleTime + pauseTime, repeats: true) { [weak self] timer in
                guard let self = self, self.isBreathingActive else {
                    timer.invalidate()
                    return
                }
                
                do {
                    let newPlayer = try hapticEngine.makePlayer(with: pattern)
                    try newPlayer.start(atTime: 0)
                } catch {
                    print("❌ Failed to play repeating haptic: \(error)")
                }
            }
            
            print("✅ Haptic breathing feedback started")
        } catch {
            print("❌ Failed to start haptic feedback: \(error)")
        }
    }
    
    private func stopHapticFeedback() {
        hapticEngine?.stop()
        print("🛑 Haptic breathing feedback stopped")
    }
    
    private func stopBreathing() {
        isBreathingActive = false
        
        // Stop heart rate monitoring
        heartRateTimer?.invalidate()
        heartRateTimer = nil
        
        // Reset the breathing node to original scale
        breathingNode?.removeAllActions()
        breathingNode?.scale = SCNVector3(1, 1, 1)
        
        // Remove particle effects
        breathingNode?.particleSystems?.forEach { particleSystem in
            breathingNode?.removeParticleSystem(particleSystem)
        }
    }
    
    private func addParticleEffects() {
        guard let node = breathingNode else { return }
        
        // Create particle system for breathing effect
        let particleSystem = SCNParticleSystem()
        particleSystem.emitterShape = breathingNode?.geometry
        particleSystem.birthRate = 20
        particleSystem.particleLifeSpan = 3.0
        particleSystem.particleSize = 0.01
        particleSystem.particleVelocity = 0.1
        particleSystem.particleVelocityVariation = 0.05
        particleSystem.particleColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.7)  // Ocean blue
        particleSystem.particleColorVariation = SCNVector4(0.1, 0.2, 0.15, 0.1)  // Ocean variation
        particleSystem.blendMode = .additive
        
        node.addParticleSystem(particleSystem)
    }
    
    private weak var sceneView: ARSCNView?
    
    func setSceneView(_ sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    private func getSceneView() -> ARSCNView? {
        return sceneView
    }
    
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ AR Session failed with error: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("⚠️ AR Session interrupted - stopping breathing")
        stopBreathing()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("✅ AR Session interruption ended")
        // Restart AR session if needed
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // AR frame updated - this means AR is working
        print("🎯 AR frame updated - session is working!")
        if breathingNode == nil && isBreathingActive {
            print("🎯 AR frame detected - creating crown jewel orb!")
            createBreathingVisualization()
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("🎯 AR anchors added: \(anchors.count)")
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("🎯 AR anchors updated: \(anchors.count)")
    }
}

// MARK: - ARKit Breathing Control Button (Removed - no pause button needed)

// MARK: - Breathing Instruction Text
struct BreathingInstructionText: View {
    let breathingPhase: Double
    @State private var currentHeartRate: Double = 75.0
    @State private var dynamicTiming = (inhale: 4.0, hold: 7.0, exhale: 8.0, pause: 1.0)
    
    private var instructionText: String {
        let totalCycle = dynamicTiming.inhale + dynamicTiming.hold + dynamicTiming.exhale + dynamicTiming.pause
        let currentTime = breathingPhase * totalCycle
        
        if currentTime <= dynamicTiming.inhale {
            let remaining = Int(dynamicTiming.inhale - currentTime + 1)
            return "Breathe In (\(remaining)s)"
        } else if currentTime <= (dynamicTiming.inhale + dynamicTiming.hold) {
            let remaining = Int(dynamicTiming.inhale + dynamicTiming.hold - currentTime + 1)
            return "Hold (\(remaining)s)"
        } else if currentTime <= (dynamicTiming.inhale + dynamicTiming.hold + dynamicTiming.exhale) {
            let remaining = Int(dynamicTiming.inhale + dynamicTiming.hold + dynamicTiming.exhale - currentTime + 1)
            return "Breathe Out (\(remaining)s)"
        } else {
            return "Pause"
        }
    }
    
    private var instructionColor: Color {
        let totalCycle = dynamicTiming.inhale + dynamicTiming.hold + dynamicTiming.exhale + dynamicTiming.pause
        let currentTime = breathingPhase * totalCycle
        
        if currentTime <= dynamicTiming.inhale {
            return Color(red: 0.3, green: 0.6, blue: 0.9)  // Ocean surface blue
        } else if currentTime <= (dynamicTiming.inhale + dynamicTiming.hold) {
            return Color(red: 0.1, green: 0.3, blue: 0.6)  // Deep ocean blue
        } else if currentTime <= (dynamicTiming.inhale + dynamicTiming.hold + dynamicTiming.exhale) {
            return Color(red: 0.15, green: 0.45, blue: 0.50)  // Sea green
        } else {
            return Color(red: 0.25, green: 0.30, blue: 0.35)  // Storm gray
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Breathing instruction only
            Text(instructionText)
                .font(.system(size: 32, weight: .light, design: .rounded))
                .foregroundColor(instructionColor)
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)
                )
                .animation(.easeInOut(duration: 0.5), value: breathingPhase)
        }
        .onAppear {
            startHeartRateSimulation()
        }
    }
    
    private func startHeartRateSimulation() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Simulate heart rate changes based on breathing (calming effect)
            let variation = Double.random(in: -2...2)
            currentHeartRate = max(60, min(95, currentHeartRate + variation))
            
            // Update breathing timing
            updateBreathingTiming()
        }
    }
    
    private func updateBreathingTiming() {
        let baseHeartRate = 75.0
        let heartRateDelta = currentHeartRate - baseHeartRate
        let adjustment = heartRateDelta / 20.0
        
        dynamicTiming.inhale = max(3.0, min(6.0, 4.0 + adjustment))
        dynamicTiming.hold = max(5.0, min(9.0, 7.0 + adjustment))
        dynamicTiming.exhale = max(6.0, min(10.0, 8.0 + adjustment))
        dynamicTiming.pause = max(0.5, min(2.0, 1.0 + adjustment * 0.5))
    }
}

// MARK: - ARKit Breathing Anchor Overlay
struct ARKitBreathingAnchorOverlay: View {
    @State private var showBreathingAnchor = false
    
    var body: some View {
        ZStack {
            if showBreathingAnchor {
                ARKitBreathingAnchor()
                    .transition(.opacity)
            }
            
            // Toggle button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showBreathingAnchor.toggle()
                        }
                    }) {
                        Image(systemName: showBreathingAnchor ? "xmark.circle.fill" : "arkit")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Preview
struct ARKitBreathingAnchor_Previews: PreviewProvider {
    static var previews: some View {
        ARKitBreathingAnchor()
            .previewDisplayName("ARKit Breathing Anchor")
    }
}