//
//  ARDemoView.swift
//  Grounded
//
//  Simple AR Demo - Just the breathing orb with live camera background
//

import SwiftUI
import ARKit
import SceneKit

struct ARDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isActive = true
    
    var body: some View {
        ZStack {
            // Full screen AR view
            ARKitBreathingAnchor { sceneView in
                print("🏆 Demo AR view ready!")
            }
            .ignoresSafeArea()
            
            // Simple close button
            VStack {
                HStack {
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                Spacer()
            }
            .padding()
            
            // Demo info
            VStack {
                Spacer()
                Text("AR Breathing Orb Demo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                
                Text("Look for the blue breathing orb floating in 3D space")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
    }
}

// Simplified ARKit view for demo
struct SimpleARKitView: UIViewRepresentable {
    let isBreathingExercise: Bool
    let breathingPhase: Double
    let onSceneViewReady: ((ARSCNView) -> Void)?
    
    init(isBreathingExercise: Bool = false, breathingPhase: Double = 0.0, onSceneViewReady: ((ARSCNView) -> Void)? = nil) {
        self.isBreathingExercise = isBreathingExercise
        self.breathingPhase = breathingPhase
        self.onSceneViewReady = onSceneViewReady
    }
    
    func makeUIView(context: Context) -> ARSCNView {
        print("🏆 Creating simple AR demo view")
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        
        // Create scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Add lighting
        setupLighting(scene: scene)
        
        // Add the breathing orb immediately
        let orb = createBreathingOrb()
        scene.rootNode.addChildNode(orb)
        context.coordinator.orbNode = orb
        print("🏆 Added breathing orb to demo scene")
        
        // Start AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        sceneView.session.run(configuration)
        
        // Notify when ready
        onSceneViewReady?(sceneView)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update orb based on breathing exercise state
        if let orbNode = context.coordinator.orbNode {
            if isBreathingExercise {
                // Breathing exercise mode: scale based on breathing phase (make much larger)
                let scale = 1.0 + (breathingPhase * 1.2) // Scale from 1.0 to 2.2
                orbNode.scale = SCNVector3(scale, scale, scale)
                print("🫁 Breathing orb scale: \(scale) (phase: \(breathingPhase))")
            } else {
                // Normal mode: reset to default scale
                orbNode.scale = SCNVector3(1.0, 1.0, 1.0)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var orbNode: SCNNode?
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            print("🏆 AR demo: Added \(anchors.count) anchors")
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            // Handle anchor updates
        }
    }
    
    private func setupLighting(scene: SCNScene) {
        // Add ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white
        ambientLight.intensity = 1000
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // Add directional light
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 2000
        
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(0, 10, 10)
        directionalNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalNode)
    }
    
    private func createBreathingOrb() -> SCNNode {
        let orb = SCNSphere(radius: 0.08)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        material.emission.contents = UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 0.3)
        material.transparency = 0.8
        orb.materials = [material]
        
        let orbNode = SCNNode(geometry: orb)
        orbNode.position = SCNVector3(0, 0, -1.5) // In front of camera
        
        // 🌊 AMAZING BREATHING ANIMATIONS!
        
        // 1. PULSING BREATHING (4-7-8 pattern)
        let breatheUp = SCNAction.scale(to: 1.4, duration: 4.0) // 4 seconds inhale
        let hold = SCNAction.wait(duration: 7.0) // 7 seconds hold
        let breatheDown = SCNAction.scale(to: 1.0, duration: 8.0) // 8 seconds exhale
        let breatheSequence = SCNAction.sequence([breatheUp, hold, breatheDown])
        let breatheRepeat = SCNAction.repeatForever(breatheSequence)
        orbNode.runAction(breatheRepeat)
        
        // 2. UP/DOWN FLOATING MOVEMENT
        let floatUp = SCNAction.moveBy(x: 0, y: 0.15, z: 0, duration: 3.0)
        let floatDown = SCNAction.moveBy(x: 0, y: -0.15, z: 0, duration: 3.0)
        let floatSequence = SCNAction.sequence([floatUp, floatDown])
        let floatRepeat = SCNAction.repeatForever(floatSequence)
        orbNode.runAction(floatRepeat)
        
        // 3. GENTLE ROTATION
        let rotate = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 12.0)
        let rotateRepeat = SCNAction.repeatForever(rotate)
        orbNode.runAction(rotateRepeat)
        
        // 4. 🌊 BUBBLE PARTICLE SYSTEM
        addBubbleParticleSystem(to: orbNode)
        
        return orbNode
    }
    
    private func addBubbleParticleSystem(to node: SCNNode) {
        // Create bubble particle system
        let bubbleSystem = SCNParticleSystem()
        bubbleSystem.particleImage = createBubbleImage()
        bubbleSystem.particleLifeSpan = 4.0
        bubbleSystem.particleLifeSpanVariation = 1.0
        bubbleSystem.particleVelocity = 0.02
        bubbleSystem.particleVelocityVariation = 0.01
        bubbleSystem.particleSize = 0.005
        bubbleSystem.particleSizeVariation = 0.003
        bubbleSystem.birthRate = 20
        bubbleSystem.emissionDuration = 0.1
        bubbleSystem.emitterShape = SCNSphere(radius: 0.05)
        
        // Bubble movement - float upward using acceleration
        bubbleSystem.acceleration = SCNVector3(0, 0.01, 0) // Gentle upward drift
        bubbleSystem.speedFactor = 1.0
        bubbleSystem.spreadingAngle = 15 // Slight spread for natural look
        
        // Bubble colors - ocean blue with transparency
        bubbleSystem.particleColor = UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.8)
        bubbleSystem.particleColorVariation = SCNVector4(0.1, 0.1, 0.1, 0.2)
        
        // Bubble transparency effects
        bubbleSystem.blendMode = .alpha
        bubbleSystem.isAffectedByGravity = false // Bubbles float, don't fall
        
        // Add to node
        node.addParticleSystem(bubbleSystem)
        print("🌊 Added bubble particle system to orb!")
    }
    
    private func createBubbleImage() -> UIImage? {
        // Create a simple bubble image
        let size = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // Draw bubble
        context?.setFillColor(UIColor.white.withAlphaComponent(0.6).cgColor)
        context?.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        context?.setLineWidth(2)
        context?.fillEllipse(in: CGRect(origin: .zero, size: size))
        context?.strokeEllipse(in: CGRect(origin: .zero, size: size))
        
        // Add highlight
        context?.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        context?.fillEllipse(in: CGRect(x: 4, y: 4, width: 6, height: 6))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
