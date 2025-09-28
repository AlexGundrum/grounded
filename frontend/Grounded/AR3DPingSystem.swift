//
//  AR3DPingSystem.swift
//  Grounded
//
//  Enhanced 3D AR Ping System with ARKit
//

import SwiftUI
import ARKit
import SceneKit

// MARK: - 3D AR Ping Ring Manager
class AR3DPingManager: ObservableObject {
    @Published var activePings: [AR3DPingRing] = []
    
    private weak var sceneView: ARSCNView?
    private var pingNodes: [String: SCNNode] = [:]
    private var isAttachedToScene: Bool { sceneView != nil }
    
    func setSceneView(_ sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    // Convert 2D screen coordinates to 3D AR world position
    func createPingRing(for object: PingARObject, at screenPosition: CGPoint, in sceneView: ARSCNView) {
        guard let camera = sceneView.session.currentFrame?.camera else {
            print("❌ No AR camera available for ping positioning")
            return
        }
        
        // Convert 2D screen coordinates to 3D world position
        let worldPosition = convert2DTo3D(
            screenPoint: screenPosition,
            camera: camera,
            sceneView: sceneView,
            targetDepth: 1.5 // 1.5 meters from camera
        )
        
        // Create the 3D ping ring
        let pingRing = AR3DPingRing(
            object: object,
            worldPosition: worldPosition,
            duration: 3.0
        )
        
        // Add to active pings
        activePings.append(pingRing)
        
        // Create and add SceneKit node
        createAndAddPingNode(for: pingRing, in: sceneView)
        
        // Auto-remove after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + pingRing.duration) {
            self.removePingRing(pingRing)
        }
        
        print("🎯 Created 3D ping ring for \(object.className) at world position \(worldPosition)")
    }
    
    private func convert2DTo3D(screenPoint: CGPoint, camera: ARCamera, sceneView: ARSCNView, targetDepth: Float) -> SCNVector3 {
        // Get the view's bounds
        let viewBounds = sceneView.bounds
        let viewWidth = Float(viewBounds.width)
        let viewHeight = Float(viewBounds.height)
        
        // Convert screen point to normalized device coordinates (-1 to 1)
        let screenX = Float(screenPoint.x)
        let screenY = Float(screenPoint.y)
        let normalizedX = (screenX / viewWidth) * 2.0 - 1.0
        let normalizedY = -((screenY / viewHeight) * 2.0 - 1.0) // Flip Y coordinate
        
        // Create a point in normalized device coordinates
        let ndcPoint = simd_float3(normalizedX, normalizedY, -1.0) // -1.0 for forward direction
        
        // Get camera transform
        let cameraTransform = camera.transform
        
        // Calculate world position at target depth
        let cameraPosition = simd_float3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        // Get camera direction vectors
        let cameraForward = normalize(simd_float3(
            -cameraTransform.columns.2.x,
            -cameraTransform.columns.2.y,
            -cameraTransform.columns.2.z
        ))
        
        let cameraRight = normalize(simd_float3(
            cameraTransform.columns.0.x,
            cameraTransform.columns.0.y,
            cameraTransform.columns.0.z
        ))
        
        let cameraUp = normalize(simd_float3(
            cameraTransform.columns.1.x,
            cameraTransform.columns.1.y,
            cameraTransform.columns.1.z
        ))
        
        // Calculate field of view scale (simplified approach)
        let imageResolutionWidth = Float(camera.imageResolution.width)
        let focalLength = camera.intrinsics[0, 0]
        let fovScale = tan(focalLength / imageResolutionWidth) // Simplified FOV scaling
        
        // Calculate offset components
        let rightOffset = cameraRight * ndcPoint.x * fovScale * targetDepth
        let upOffset = cameraUp * ndcPoint.y * fovScale * targetDepth
        let forwardOffset = cameraForward * targetDepth
        
        // Project the point into 3D space
        let worldOffset = rightOffset + upOffset + forwardOffset
        let worldPosition = cameraPosition + worldOffset
        
        return SCNVector3(worldPosition.x, worldPosition.y, worldPosition.z)
    }
    
    private func createAndAddPingNode(for pingRing: AR3DPingRing, in sceneView: ARSCNView) {
        // Create the 3D ring geometry
        let ringGeometry = createPingRingGeometry(for: pingRing.object)
        let pingNode = SCNNode(geometry: ringGeometry)
        
        // Position the node
        pingNode.position = pingRing.worldPosition
        
        // Make the ring always face the camera
        pingNode.constraints = [SCNBillboardConstraint()]
        
        // Add to scene
        sceneView.scene.rootNode.addChildNode(pingNode)
        
        // Store reference
        pingNodes[pingRing.id.uuidString] = pingNode
        
        // Start animation
        animatePingRing(node: pingNode, duration: pingRing.duration)
    }
    
    private func createPingRingGeometry(for object: PingARObject) -> SCNGeometry {
        // Create a smaller torus ring (similar to breathing ring but smaller)
        let ringRadius: CGFloat = 0.08 // 8cm ring
        let pipeRadius: CGFloat = 0.008 // 8mm thickness
        
        let torus = SCNTorus(ringRadius: ringRadius, pipeRadius: pipeRadius)
        
        // Create object-specific material
        let material = createPingMaterial(for: object)
        torus.materials = [material]
        
        return torus
    }
    
    private func createPingMaterial(for object: PingARObject) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Base color based on object type
        let baseColor = getPingColor(for: object)
        material.diffuse.contents = baseColor
        
        // Emission for glow effect
        material.emission.contents = baseColor.withAlphaComponent(0.6)
        
        // Metallic properties for premium look
        material.metalness.contents = 0.8
        material.roughness.contents = 0.2
        
        // Transparency
        material.transparency = 0.9
        material.blendMode = .add
        
        return material
    }
    
    private func getPingColor(for object: PingARObject) -> UIColor {
        switch object.className.lowercased() {
        case let name where name.contains("chair") || name.contains("table") || name.contains("furniture"):
            return UIColor.brown
        case let name where name.contains("plant") || name.contains("tree"):
            return UIColor.systemGreen
        case let name where name.contains("tv") || name.contains("computer") || name.contains("phone"):
            return UIColor.systemPurple
        case let name where name.contains("bottle") || name.contains("cup") || name.contains("glass"):
            return UIColor.systemOrange
        case let name where name.contains("person"):
            return UIColor.systemBlue
        default:
            return UIColor.systemCyan
        }
    }
    
    private func animatePingRing(node: SCNNode, duration: TimeInterval) {
        // Scale animation: start small, grow, then shrink
        node.scale = SCNVector3(0.1, 0.1, 0.1)
        
        // Grow animation
        let growAction = SCNAction.scale(to: 1.2, duration: duration * 0.3)
        growAction.timingMode = .easeOut
        
        // Pulse animation
        let pulseScale = SCNAction.scale(to: 1.0, duration: duration * 0.4)
        pulseScale.timingMode = .easeInEaseOut
        
        // Shrink and fade
        let shrinkAction = SCNAction.scale(to: 0.1, duration: duration * 0.3)
        shrinkAction.timingMode = .easeIn
        
        let fadeAction = SCNAction.fadeOut(duration: duration * 0.3)
        let finalActions = SCNAction.group([shrinkAction, fadeAction])
        
        // Rotation for visual appeal
        let rotationAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: duration)
        let repeatRotation = SCNAction.repeatForever(rotationAction)
        
        // Combine animations
        let scaleSequence = SCNAction.sequence([growAction, pulseScale, finalActions])
        
        // Run animations
        node.runAction(scaleSequence, forKey: "pingAnimation")
        node.runAction(repeatRotation, forKey: "rotation")
    }
    
    private func removePingRing(_ pingRing: AR3DPingRing) {
        // Remove from active pings
        activePings.removeAll { $0.id == pingRing.id }
        
        // Remove from scene
        if let node = pingNodes[pingRing.id.uuidString] {
            node.removeFromParentNode()
            pingNodes.removeValue(forKey: pingRing.id.uuidString)
        }
        
        print("🗑️ Removed 3D ping ring for \(pingRing.object.className)")
    }
    
    func clearAllPings() {
        for pingRing in activePings {
            removePingRing(pingRing)
        }
    }
}

// MARK: - 3D AR Ping Ring Model
struct AR3DPingRing: Identifiable {
    let id = UUID()
    let object: PingARObject
    let worldPosition: SCNVector3
    let duration: TimeInterval
    let createdAt = Date()
}

// MARK: - ARKit Integration for Existing Ping System
extension PingARManager {
    func triggerPingForObjectsIn3D(_ objectNames: [String], sceneView: ARSCNView?) {
        print("🔔 LLM triggered 3D ping for objects: \(objectNames)")
        
        guard let sceneView = sceneView else {
            print("❌ No ARSCNView available for 3D pings")
            // Fallback to 2D pings
            triggerPingForObjects(objectNames)
            return
        }
        
        // Find matching objects from current detections
        let matchingObjects = detectedObjects.filter { object in
            objectNames.contains { name in
                object.className.lowercased().contains(name.lowercased()) ||
                name.lowercased().contains(object.className.lowercased())
            }
        }
        
        // Create 3D ping rings for each matching object
        let ar3DManager = AR3DPingManager()
        ar3DManager.setSceneView(sceneView)
        
        for object in matchingObjects {
            // Convert normalized coordinates to screen coordinates
            let screenSize = sceneView.bounds.size
            let screenPoint = CGPoint(
                x: object.normalizedX * screenSize.width,
                y: object.normalizedY * screenSize.height
            )
            
            ar3DManager.createPingRing(for: object, at: screenPoint, in: sceneView)
        }
        
        print("✨ Created \(matchingObjects.count) 3D ping rings")
    }
}

// MARK: - SwiftUI Integration
struct AR3DPingOverlay: View {
    @ObservedObject var pingManager: AR3DPingManager
    
    var body: some View {
        // This overlay is mainly for monitoring active pings
        // The actual 3D rings are rendered in ARSCNView
        VStack {
            HStack {
                Spacer()
                if !pingManager.activePings.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        ForEach(pingManager.activePings) { ping in
                            Text("📍 \(ping.object.className)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.black.opacity(0.7))
                                )
                        }
                    }
                    .padding()
                }
            }
            Spacer()
        }
    }
}
