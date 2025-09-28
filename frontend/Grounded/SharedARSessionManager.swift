
//
//  SharedARSessionManager.swift
//  Grounded
//
//  Created by Kori Russell on 9/27/25.
//

import Foundation
import ARKit
import Combine

class SharedARSessionManager: NSObject, ARSessionDelegate, ObservableObject {
    @Published var session: ARSession
    @Published var currentFrame: ARFrame?
    
    private var configuration: ARConfiguration
    
    init(configuration: ARConfiguration = ARWorldTrackingConfiguration()) {
        self.session = ARSession()
        self.configuration = configuration
        super.init()
        self.session.delegate = self
    }
    
    func run() {
        // Ensure we have a fresh configuration
        let newConfiguration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            newConfiguration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        self.configuration = newConfiguration
        
        print("🚀 Running shared AR session")
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func pause() {
        print("⏸️ Pausing shared AR session")
        session.pause()
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        currentFrame = frame
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ AR session failed with error: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("⚠️ AR session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("✅ AR session interruption ended")
        run()
    }
    
    // MARK: - Image Capture
    
    func captureImage(completion: @escaping (Data?) -> Void) {
        guard let frame = currentFrame else {
            print("❌ Cannot capture image, no current ARFrame")
            completion(nil)
            return
        }
        
        let pixelBuffer = frame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("❌ Failed to create CGImage from CVPixelBuffer")
            completion(nil)
            return
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        // Convert to JPEG data
        let jpegData = uiImage.jpegData(compressionQuality: 0.7)
        
        print("📸 Image captured from shared AR session")
        completion(jpegData)
    }
}
