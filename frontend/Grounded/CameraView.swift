//
//  CameraView.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import SwiftUI
import AVFoundation
import AVKit
import UIKit
import Speech
import Combine

struct CameraView: UIViewControllerRepresentable {
    let crisisManager: CrisisManager
    var videoCaptureEnabled: Bool = true
    
    func makeUIViewController(context: Context) -> ContinuousCameraViewController {
        let controller = ContinuousCameraViewController()
        controller.crisisManager = crisisManager
        controller.videoCaptureEnabled = videoCaptureEnabled
        crisisManager.cameraController = controller // Set reference for speech control
        
        // Set camera controller for AR managers to enable real image capture
        crisisManager.realTimeARManager.cameraController = controller
        crisisManager.pingARManager.cameraController = controller
        
        // Set crisis manager reference for phase coordination
        crisisManager.pingARManager.crisisManager = crisisManager
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ContinuousCameraViewController, context: Context) {
        uiViewController.videoCaptureEnabled = videoCaptureEnabled
    }
}

// MARK: - Camera View with Overlay

struct CameraViewWithOverlay: View {
    @ObservedObject var crisisManager: CrisisManager
    
    var body: some View {
        ZStack {
            // PHASE 1: CV Scanning - Show camera feed
            if crisisManager.isInComputerVisionPhase() {
                CameraView(crisisManager: crisisManager, videoCaptureEnabled: true)
            }
            // PHASE 2: AR Mode - ARKit handles camera, no separate CameraView needed
            
            // PHASE 1: CV Scanning - No AR overlays to prevent Metal conflicts
            if crisisManager.isInComputerVisionPhase() {
                VStack {
                    HStack {
                        Spacer()
                        // Phase indicators removed as requested
                            .padding()
                    }
                    Spacer()
                }
            } else {
                // PHASE 2: AR Mode - EXACTLY like the working AR demo!
                // Just show the AR orb - no complex overlays, no background gradients
                SimpleARKitView(
                    isBreathingExercise: crisisManager.isBreathingExerciseActive,
                    breathingPhase: crisisManager.breathingPhase
                ) { sceneView in
                    print("🏆 AR Mode scene ready - just like the demo!")
                }
                .ignoresSafeArea()
                .onAppear {
                    print("🏆 TRANSITIONING TO AR MODE - Using demo approach!")
                    print("🏆 AR Mode active - clean AR orb like the demo!")
                    }
                }

            VStack {
                // Beautiful Bottom Caption Display
                BottomCaptionView(crisisManager: crisisManager)
            }
            
            // Removed test controls from main UI
            
            // Video Call Overlay (simple overlay on camera feed)
            if crisisManager.isVideoCallActive {
                VideoCallOverlay()
            }
        }
    }
}

class ContinuousCameraViewController: UIViewController {
    var crisisManager: CrisisManager?
    var videoCaptureEnabled: Bool = true {
        didSet {
            if videoCaptureEnabled {
                startCameraIfNeeded()
            } else {
                stopCameraPreview()
            }
        }
    }
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var imageCaptureTimer: Timer?
    private var audioRecorder: AVAudioRecorder?
    private var speechRecognizer: SFSpeechRecognizer?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var audioEngine: AVAudioEngine?
    @Published var recognizedText: String = ""
    private var audioLevelTimer: Timer?
    
    // Fixed photo output to prevent blinking
    private var photoOutput: AVCapturePhotoOutput?
    
    // Video output to keep preview flowing
    private var videoOutput: AVCaptureVideoDataOutput?
    
    // Camera session stability
    private var isCameraSetupComplete = false
    private var pendingCaptureRequests: [(Data?) -> Void] = []
    
    // Capture queue to prevent concurrent captures that freeze preview
    private var isCapturingPhoto = false
    private var captureQueue: [(Data?) -> Void] = []
    
    // Speech recognition control with debounce
    private var isSpeechRecognitionPaused: Bool = false
    private var speechDebounceTimer: Timer?
    var pendingSpeechText: String = ""
    private let speechDebounceDelay: TimeInterval = 2.0 // Wait 2s for silence - balanced for responsiveness
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupAudioRecording()
        setupSpeechRecognition()
        startContinuousMonitoring()
        
        // Ensure camera is always enabled for image capture
        videoCaptureEnabled = true
        
        // Give camera setup a moment to complete, then force start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.ensureCameraIsRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update preview layer frame to prevent freeze on rotation/layout changes
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only stop monitoring if we're actually leaving the camera view
        // Don't stop during app startup or background transitions
        if !isViewLoaded || view.window == nil {
        stopContinuousMonitoring()
        }
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            crisisManager?.handleError("Camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            // Add photo output once during setup (not every capture)
            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, captureSession!.canAddOutput(photoOutput) {
                captureSession?.addOutput(photoOutput)
                print("✅ Photo output added during setup")
            }
            
            // Add video output to keep preview flowing and prevent freeze
            videoOutput = AVCaptureVideoDataOutput()
            if let videoOutput = videoOutput, captureSession!.canAddOutput(videoOutput) {
                let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
                videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                captureSession?.addOutput(videoOutput)
                print("✅ Video output added to prevent preview freeze")
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds
            view.layer.addSublayer(previewLayer!)
            
            // Ensure preview layer updates properly to prevent freeze
            if #available(iOS 17.0, *) {
            previewLayer?.connection?.videoRotationAngle = 90
        } else {
            previewLayer?.connection?.videoOrientation = .portrait
        }
            
            // ALWAYS start camera for image capture - don't wait for videoCaptureEnabled
            print("📸 Starting camera session immediately during setup...")
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
                print("✅ Camera session force-started during setup")
            }
        } catch {
            crisisManager?.handleError("Camera setup failed")
        }
    }

    private func startCameraIfNeeded() {
        guard videoCaptureEnabled else { 
            print("❌ Video capture disabled - cannot start camera")
            return 
        }
        
        print("📸 Starting camera session...")
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession?.isRunning == false {
                self.captureSession?.startRunning()
                DispatchQueue.main.async {
                print("✅ Camera session started successfully")
                }
            } else {
                DispatchQueue.main.async {
                print("📸 Camera session already running")
                }
            }
        }
    }
    
    private func ensureCameraIsRunning() {
        print("🔧 Ensuring camera is running for image capture...")
        guard let captureSession = captureSession else {
            print("❌ No capture session available")
            return
        }
        
        if !captureSession.isRunning {
            print("🔧 Camera session not running - forcing start")
            videoCaptureEnabled = true
            startCameraIfNeeded()
        } else {
            print("✅ Camera session is running properly")
        }
    }
    
    func stopCameraPreview() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession?.isRunning == true {
                self.captureSession?.stopRunning()
            }
        }
    }
    
    // MARK: - Audio Recording Setup
    
    private func setupAudioRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Use playAndRecord with echo cancellation and noise suppression
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat, // Better echo cancellation than .default
                options: [
                    .defaultToSpeaker,
                    .allowBluetooth,
                    .mixWithOthers // Prevents audio conflicts
                ]
            )
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("crisis_audio.m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
            print("✅ Audio recording setup successful")
        } catch {
            print("❌ Audio recording setup failed: \(error)")
        }
    }
    
    // MARK: - Speech Recognition Setup
    
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        guard let speechRecognizer = speechRecognizer else {
            print("❌ Speech recognition not available")
            return
        }
        
        guard speechRecognizer.isAvailable else {
            print("❌ Speech recognition not available")
            return
        }
        
        print("✅ Speech recognition setup successful")
    }
    
    // MARK: - Continuous Monitoring
    
    private func startContinuousMonitoring() {
        // Start audio recording
        if audioRecorder?.record() == true {
            print("🎤 Audio recording started")
        } else {
            print("❌ Failed to start audio recording")
        }
        
        // Start speech recognition
        startSpeechRecognition()
        
        // Image capture disabled - focusing on conversation only
        // Image capture disabled - focusing on conversation
    }
    
    func startSpeechRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("❌ Speech recognizer not available")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let newText = result.bestTranscription.formattedString
                    self?.recognizedText = newText
                    print("🎤 Speech recognized (live): '\(newText)' (final: \(result.isFinal))")
                    
                    // Implement debounce: only send after silence
                    if !newText.isEmpty {
                        print("Processing speech: '\(newText)' (final: \(result.isFinal))")
                        self?.handleSpeechWithDebounce(newText, isFinal: result.isFinal)
                    }
                }
                
                if let error = error {
                    print("Speech recognition error: \(error)")
                    
                    // Handle specific error codes
                    if let nsError = error as NSError? {
                        switch nsError.code {
                        case 1110: // No speech detected
                            print("No speech detected - this is normal during silence")
                        case 1101: // Service error
                            print("Speech recognition service error - will retry")
                            // Don't restart immediately, let the system handle it
                        default:
                            print("Speech recognition error code: \(nsError.code)")
                        }
                    }
                }
            }
        }
        
        // Set up audio engine for real-time speech recognition
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("✅ Speech recognition started")
        } catch {
            print("❌ Speech recognition start failed: \(error)")
        }
    }
    
    
    private func getCurrentAudioLevel() -> Float? {
        guard let audioEngine = audioEngine else { return nil }
        
        let inputNode = audioEngine.inputNode
        let _ = inputNode.outputFormat(forBus: 0)
        
        // This is a simplified audio level detection
        // In a real implementation, you'd use AVAudioEngine's tap to get actual levels
        return 0.0 // Placeholder - would need proper audio level monitoring
    }
    
    func pauseSpeechRecognition() {
        isSpeechRecognitionPaused = true
        
        // Clear all buffers
        pendingSpeechText = ""
        speechDebounceTimer?.invalidate()
        speechDebounceTimer = nil
        
        print("Speech recognition paused - no AI leakage possible")
    }
    
    func resumeSpeechRecognition() {
        isSpeechRecognitionPaused = false
        
        print("Resuming speech recognition...")
        
        // Don't restart speech recognition - just resume the existing session
        // This prevents the kAFAssistantErrorDomain Code=1110 errors
    }
    
    func stopSpeechRecognition() {
        // Completely stop speech recognition during TTS
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        print("🛑 Speech recognition completely stopped for TTS")
    }
    
    func restartSpeechRecognition() {
        // Restart speech recognition after TTS
        startSpeechRecognition()
        print("🔄 Speech recognition restarted after TTS")
    }
    
    // MARK: - Speech Debounce Logic
    
    private func handleSpeechWithDebounce(_ text: String, isFinal: Bool) {
        // PREVENT user interruption during TTS - speech recognition should be paused
        guard !isSpeechRecognitionPaused else {
            print("🚫 Speech recognition paused - ignoring user input during TTS")
            return
        }
        
        // Check if listening is enabled OR AI is speaking OR special request is active - ignore speech in all cases
        if let crisisManager = crisisManager, (!crisisManager.isListeningEnabled || crisisManager.isTTSPlaying || crisisManager.isSpecialRequestActive) {
            print("Speech ignored - isListeningEnabled: \(crisisManager.isListeningEnabled), isTTSPlaying: \(crisisManager.isTTSPlaying), isSpecialRequestActive: \(crisisManager.isSpecialRequestActive)")
            print("Speech ignored (AI speaking, Anchor message, or special request - preventing echo): '\(text)'")
            return
        }
        
        // Store the latest speech text
        pendingSpeechText = text
        
        // If this is a final result, send immediately
        if isFinal {
            print("🎤 Speech final - sending immediately: '\(text)'")
            sendPendingSpeech()
            return
        }
        
        // Reset the debounce timer
        speechDebounceTimer?.invalidate()
        speechDebounceTimer = Timer.scheduledTimer(withTimeInterval: speechDebounceDelay, repeats: false) { [weak self] _ in
            print("🎤 Speech debounce complete - sending after silence: '\(self?.pendingSpeechText ?? "")'")
            self?.sendPendingSpeech()
        }
        
        print("🔄 Speech debounce timer reset for: '\(text)'")
    }
    
    private func sendPendingSpeech() {
        guard !pendingSpeechText.isEmpty else { return }
        
        // Double-check AI is not speaking before processing
        if let crisisManager = crisisManager, crisisManager.isTTSPlaying {
            print("🚫 AI still speaking - deferring speech processing: '\(pendingSpeechText)'")
            return
        }
        
        // Update the userSpeech property in CrisisManager
        crisisManager?.userSpeech = pendingSpeechText

        // Send the completed speech to crisis manager with proper segmentation
        crisisManager?.processSpeechText(pendingSpeechText)
        
        // Clear the pending text after a delay to keep it on screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.crisisManager?.userSpeech = ""
        }

        pendingSpeechText = ""
        speechDebounceTimer?.invalidate()
        speechDebounceTimer = nil
    }
    
    private func stopContinuousMonitoring() {
        imageCaptureTimer?.invalidate()
        imageCaptureTimer = nil
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        speechDebounceTimer?.invalidate()
        speechDebounceTimer = nil
        audioRecorder?.stop()
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        captureSession?.stopRunning()
        print("🛑 Continuous monitoring stopped")
    }
    
    func captureAndSendImage() {
        print("📸 captureAndSendImage() called - starting real camera capture")
        guard let photoOutput = photoOutput else { 
            print("❌ No photo output available")
            return 
        }
        
        guard let captureSession = captureSession else {
            print("❌ No capture session available")
            return
        }
        
        guard captureSession.isRunning else {
            print("❌ Capture session not running - attempting to start it")
            ensureCameraIsRunning()
            
            // Retry capture after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.captureAndSendImage()
            }
            return 
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        
        // Simple photo settings - disable high resolution to avoid crash
        // Use default photo dimensions - let system choose supported resolution
        // Backend will handle resizing to 640x384 as needed
        if #available(iOS 16.0, *) {
            // Don't set maxPhotoDimensions - use system default
        } else {
            settings.isHighResolutionPhotoEnabled = false
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("📸 Photo capture initiated with running session")
    }
    
    // Method for AR managers to capture real camera frames
    func captureImageForProcessing(completion: @escaping (Data?) -> Void) {
        // Queue capture requests to prevent concurrent captures that freeze preview
        if isCapturingPhoto {
            print("📸 Photo capture in progress - queueing request")
            captureQueue.append(completion)
            return
        }
        
        print("📸 AR manager requesting real camera frame")
        guard let photoOutput = photoOutput else { 
            print("❌ No photo output available for AR processing")
            completion(nil)
            processNextCaptureInQueue()
            return 
        }
        
        guard let captureSession = captureSession else {
            print("❌ No capture session available for AR processing")
            completion(nil)
            processNextCaptureInQueue()
            return
        }
        
        guard captureSession.isRunning else {
            print("❌ Capture session not running for AR processing - skipping to prevent freeze")
            completion(nil)
            processNextCaptureInQueue()
            return
        }
        
        isCapturingPhoto = true
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        
        // Use default photo dimensions - let system choose supported resolution
        // Backend will handle resizing to 640x384 as needed
        if #available(iOS 16.0, *) {
            // Don't set maxPhotoDimensions - use system default
        } else {
            settings.isHighResolutionPhotoEnabled = false
        }
        
        // Store completion handler for AR processing
        arProcessingCompletion = completion
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("📸 Real camera frame capture initiated for AR processing")
    }
    
    // Process next capture in queue
    private func processNextCaptureInQueue() {
        guard !captureQueue.isEmpty else { return }
        
        let nextCompletion = captureQueue.removeFirst()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.captureImageForProcessing(completion: nextCompletion)
        }
    }
    
    // Completion handler for AR processing
    private var arProcessingCompletion: ((Data?) -> Void)?
    
    // Process any pending capture requests after camera setup
    private func processPendingCaptureRequests() {
        guard isCameraSetupComplete, !pendingCaptureRequests.isEmpty else { return }
        
        print("📸 Processing \(pendingCaptureRequests.count) pending capture requests")
        for completion in pendingCaptureRequests {
            captureImageForProcessing(completion: completion)
        }
        pendingCaptureRequests.removeAll()
    }
}

// MARK: - Video Data Output Delegate (Prevents Preview Freeze)

extension ContinuousCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // This delegate method keeps the preview flowing to prevent freeze
        // We don't need to process every frame here, just keep the pipeline active
        // The photo capture handles the actual image processing
    }
}

// MARK: - Photo Capture Delegate

extension ContinuousCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📸 Photo capture delegate called - processing real camera image")
        if let error = error {
            print("❌ Photo capture error: \(error.localizedDescription)")
            crisisManager?.handleError("Photo capture failed: \(error.localizedDescription)")
            
            // Also handle AR processing completion if it was requested
            if let completion = arProcessingCompletion {
                completion(nil)
                arProcessingCompletion = nil
            }
            
            // Mark capture as complete even on error to prevent queue backup
            isCapturingPhoto = false
            processNextCaptureInQueue()
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to convert photo to image data")
            crisisManager?.handleError("Failed to process captured image")
            
            // Also handle AR processing completion if it was requested
            if let completion = arProcessingCompletion {
                completion(nil)
                arProcessingCompletion = nil
            }
            
            // Mark capture as complete even on conversion error
            isCapturingPhoto = false
            processNextCaptureInQueue()
            return
        }
        
        print("✅ Real camera image captured: \(image.size.width)x\(image.size.height)")
        
        // Notify CrisisManager of successful camera capture (for Anchor voice timing)
        crisisManager?.onSuccessfulCameraCapture()
        
        // If this was for AR processing, handle that first
        if let completion = arProcessingCompletion {
            // Convert image to JPEG data for AR processing
            let jpegData = image.jpegData(compressionQuality: 0.7)
            completion(jpegData)
            arProcessingCompletion = nil
            print("📸 Image data provided to AR manager for real detection")
            
            // Mark capture as complete and process next in queue
            isCapturingPhoto = false
            processNextCaptureInQueue()
        } else {
            // Regular image processing for visual context
        crisisManager?.processCapturedImage(image)
            
            // Mark capture as complete
            isCapturingPhoto = false
        }
    }
}

// MARK: - Camera Permission Helper

class CameraPermissionManager: ObservableObject {
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.checkPermission()
            }
        }
    }
}

// MARK: - AR Overlay View
struct AROverlayView: View {
    @ObservedObject var arOverlayState: AROverlayState
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Only show AR content when there are objects or instructions
                if !arOverlayState.arObjects.isEmpty || !arOverlayState.currentInstruction.isEmpty {
                    // AR Object Overlays
                    ForEach(arOverlayState.arObjects) { arObject in
                        ARObjectOverlay(
                            arObject: arObject,
                            screenSize: geometry.size
                        )
                    }
                    
                    // Directional Arrow (if needed)
                    if arOverlayState.showDirectionalArrow,
                       let targetObject = arOverlayState.arrowTarget {
                        DirectionalArrowView(
                            targetObject: targetObject,
                            screenSize: geometry.size
                        )
                    }
                    
                    // Instruction Text
                    if !arOverlayState.currentInstruction.isEmpty {
                        VStack {
                            Spacer()
                            Text(arOverlayState.currentInstruction)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.black.opacity(0.7))
                                )
                                .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Blue Breathing Orb (Non-AR Overlay)
struct BlueBreathingOrbOverlay: View {
    @State private var breathe: Bool = false
    @State private var floatUp: Bool = false
    @State private var glowPulse: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Soft outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 180
                        )
                    )
                    .frame(width: 260, height: 260)
                    .scaleEffect(glowPulse ? 1.15 : 0.95)
                    .opacity(glowPulse ? 0.8 : 0.5)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: glowPulse)
                
                // Main orb with subtle gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.2, green: 0.4, blue: 0.95),
                                Color(red: 0.1, green: 0.2, blue: 0.6)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 120
                        )
                    )
                    .frame(width: 180, height: 180)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.blue.opacity(0.6), radius: 20, x: 0, y: 10)
                    .scaleEffect(breathe ? 1.12 : 0.88)
                    .animation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true), value: breathe)
                
                // Inner heartbeat pulse
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(glowPulse ? 1.05 : 0.95)
                    .opacity(glowPulse ? 0.9 : 0.5)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: glowPulse)
            }
            .offset(y: floatUp ? -8 : 8)
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floatUp)
            .padding(.bottom, 140)
        }
        .onAppear {
            breathe = true
            floatUp = true
            glowPulse = true
        }
    }
}

// MARK: - AR Object Overlay
struct ARObjectOverlay: View {
    let arObject: ARObject
    let screenSize: CGSize
    @State private var isPulsing = false
    
    var body: some View {
        let x = arObject.normalizedX * screenSize.width
        let y = arObject.normalizedY * screenSize.height
        
        ZStack {
            // Clean pulsing circle - Forest style
            Circle()
                .stroke(Color(red: 0.15, green: 0.45, blue: 0.50), lineWidth: 4)
                .frame(width: 100, height: 100)
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isPulsing
                )
            
            // Clean object label
            Text(arObject.label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.15, green: 0.45, blue: 0.50).opacity(0.9))
                )
                .offset(y: 60)
        }
        .position(x: x, y: y)
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Directional Arrow View
struct DirectionalArrowView: View {
    let targetObject: ARObject
    let screenSize: CGSize
    @State private var isAnimating = false
    
    var body: some View {
        let targetX = targetObject.normalizedX * screenSize.width
        let targetY = targetObject.normalizedY * screenSize.height
        
        // Clean arrow pointing to target object
        Image(systemName: "arrow.up.circle.fill")
            .font(.system(size: 35))
            .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.50))
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .position(x: targetX, y: targetY - 80)
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Beautiful Bottom Caption View with Scrolling Text

struct BottomCaptionView: View {
    @ObservedObject var crisisManager: CrisisManager
    @State private var displayedText: String = ""
    @State private var showCaption: Bool = false
    @State private var isTyping: Bool = false
    @State private var currentPosition: Int = 0
    @State private var scrollTimer: Timer?
    @State private var currentPage: Int = 0
    @State private var pageHeight: CGFloat = 0
    @State private var totalPages: Int = 1
    @State private var scrollOffset: CGFloat = 0
    
    // Computed property for highlighted text
    private var highlightedText: AttributedString {
        var attributedString = AttributedString(displayedText)
        
        if crisisManager.isTTSPlaying && currentPosition > 0 && currentPosition < displayedText.count {
            // Highlight current position using String-based approach
            let safePosition = min(currentPosition, displayedText.count)
            let prefix = String(displayedText.prefix(safePosition))
            let suffix = String(displayedText.suffix(displayedText.count - safePosition))
            
            // Create attributed string with highlighting
            var highlightedString = AttributedString(prefix)
            highlightedString.backgroundColor = Color(red: 0.15, green: 0.45, blue: 0.50).opacity(0.3)
            
            let suffixString = AttributedString(suffix)
            attributedString = highlightedString + suffixString
        }
        
        return attributedString
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            // Position in bottom third of screen
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.4) // Push to bottom third
                
                if showCaption && !displayedText.isEmpty {
                    VStack(spacing: 16) {
                        // Elegant caption container
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                // Status indicator
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(isTyping ? Color(red: 0.3, green: 0.6, blue: 0.9) : Color(red: 0.15, green: 0.45, blue: 0.50))
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(isTyping ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isTyping)
                                    
                                    Text(isTyping ? "Anchor responding..." : "Anchor")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                        .fontWeight(.medium)
                                }
                                
                                // Teleprompter-style scrolling text
                                ScrollViewReader { proxy in
                                    ScrollView(.vertical, showsIndicators: false) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            // Full text with highlighted current position and page markers
                                            VStack(alignment: .leading, spacing: 0) {
                                                ForEach(0..<totalPages, id: \.self) { pageIndex in
                                                    let pageText = getPageText(for: pageIndex)
                                                    
                                                    Text(pageText)
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .id("page_\(pageIndex)")
                                                        .padding(.bottom, pageIndex < totalPages - 1 ? 20 : 0)
                                                }
                                            }
                                            .background(
                                                GeometryReader { geometry in
                                                    Color.clear
                                                        .onAppear {
                                                            pageHeight = geometry.size.height
                                                            calculateTotalPages()
                                                        }
                                                        .onChange(of: displayedText) { _, _ in
                                                            calculateTotalPages()
                                                        }
                                                }
                                            )
                                            
                                            // Progress indicator
                                            if crisisManager.isTTSPlaying && !displayedText.isEmpty {
                                                HStack {
                                                    Text("Page \(currentPage + 1)/\(totalPages) • \(currentPosition)/\(displayedText.count) chars")
                                                        .font(.caption2)
                                                        .foregroundColor(.white.opacity(0.7))
                                                    
                                                    Spacer()
                                                    
                                                    // Progress bar
                                                    ProgressView(value: Double(currentPosition), total: Double(displayedText.count))
                                                        .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.15, green: 0.45, blue: 0.50)))
                                                        .frame(width: 100)
                                                }
                                                .padding(.top, 8)
                                            }
                                        }
                                        .padding(.vertical, 20)
                                    }
                                    .frame(maxHeight: 200) // Limit height to create pagination
                                    .onChange(of: currentPosition) { _, _ in
                                        // Calculate which page we should be on based on current position
                                        guard pageHeight > 0, totalPages > 1 else { return }
                                        
                                        let charactersPerPage = displayedText.count / totalPages
                                        let targetPage = min(currentPosition / max(1, charactersPerPage), totalPages - 1)
                                        
                                        if targetPage != currentPage {
                                            currentPage = targetPage
                                            
                                            // Smooth scroll to the appropriate position
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                proxy.scrollTo("page_\(targetPage)", anchor: .top)
                                            }
                                            
                                            print("📄 Teleprompter: Scrolled to page \(targetPage + 1)/\(totalPages)")
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(red: 0.15, green: 0.45, blue: 0.50).opacity(0.4), lineWidth: 1.5)
                                )
                                .shadow(color: Color(red: 0.05, green: 0.15, blue: 0.35).opacity(0.4), radius: 15, x: 0, y: 8)
                        )
                    }
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCaption)
                }
                
                Spacer()
                    .frame(height: 60) // Bottom margin for safe area
            }
        }
        .onChange(of: crisisManager.lastAIResponse) { _, newResponse in
            updateCaption(with: newResponse)
        }
        .onChange(of: crisisManager.isTTSPlaying) { _, isPlaying in
            isTyping = isPlaying && !crisisManager.lastAIResponse.isEmpty
            
            if isPlaying {
                startScrollingTimer()
            } else {
                stopScrollingTimer()
                currentPosition = 0
            }
        }
    }
    
    private func updateCaption(with newText: String) {
        guard !newText.isEmpty else {
            hideCaption()
            return
        }
        
        // Show typing indicator first
        withAnimation(.easeInOut(duration: 0.3)) {
            isTyping = true
            showCaption = true
        }
        
        // Animate text appearance with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                displayedText = newText
                isTyping = false
            }
        }
        
        // Auto-hide after showing for a while (only if AI isn't actively speaking)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            if !crisisManager.isTTSPlaying {
                hideCaption()
            }
        }
    }
    
    private func hideCaption() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showCaption = false
            isTyping = false
        }
        
        stopScrollingTimer()
        currentPosition = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            displayedText = ""
        }
    }
    
    private func startScrollingTimer() {
        stopScrollingTimer() // Stop any existing timer
        
        guard !displayedText.isEmpty else { return }
        
        // Calculate scroll speed based on text length (roughly 3 characters per second)
        let totalDuration = Double(displayedText.count) / 3.0
        let interval = 0.1 // Update every 100ms
        let increment = max(1, Int(Double(displayedText.count) * interval / totalDuration))
        
        scrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if self.currentPosition < self.displayedText.count {
                self.currentPosition = min(self.currentPosition + increment, self.displayedText.count)
            } else {
                self.stopScrollingTimer()
            }
        }
    }
    
    private func stopScrollingTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
    // Calculate total pages based on text length and available height
    private func calculateTotalPages() {
        guard pageHeight > 0 else { return }
        
        // Estimate characters per page based on font size and height
        let charactersPerLine = 40 // Approximate characters per line
        let linesPerPage = Int(pageHeight / 25) // Approximate lines per page (25pt line height)
        let charactersPerPage = charactersPerLine * linesPerPage
        
        totalPages = max(1, Int(ceil(Double(displayedText.count) / Double(charactersPerPage))))
    }
    
    // Get text for a specific page
    private func getPageText(for pageIndex: Int) -> AttributedString {
        guard totalPages > 1 else { return highlightedText }
        
        let charactersPerPage = displayedText.count / totalPages
        let startIndex = pageIndex * charactersPerPage
        let endIndex = min(startIndex + charactersPerPage, displayedText.count)
        
        let pageText = String(displayedText.prefix(endIndex).suffix(endIndex - startIndex))
        var attributedString = AttributedString(pageText)
        
        // Apply highlighting for current position within this page
        if crisisManager.isTTSPlaying && currentPosition > startIndex {
            let highlightEnd = min(currentPosition - startIndex, pageText.count)
            if highlightEnd > 0 {
                // Use string-based highlighting approach
                let highlightedText = String(pageText.prefix(highlightEnd))
                let remainingText = String(pageText.suffix(pageText.count - highlightEnd))
                
                var highlightedPart = AttributedString(highlightedText)
                highlightedPart.backgroundColor = Color(red: 0.15, green: 0.45, blue: 0.50).opacity(0.3)
                
                let remainingPart = AttributedString(remainingText)
                attributedString = highlightedPart + remainingPart
            }
        }
        
        return attributedString
    }
    
}

// MARK: - Video Call Overlay (Simple overlay on camera feed)
struct VideoCallOverlay: View {
    @State private var playerVolume: Float = 1.0
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop over camera
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Autoplay video with no controls
            AVPlayerLayerView(url: Bundle.main.url(forResource: "specialvideo", withExtension: "MOV")!, volume: 1.0)
                .frame(width: 320, height: 220)
                .background(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                )
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.9), radius: 18)
        }
    }
}

// MARK: - AVPlayerLayer-backed SwiftUI view (no controls, autoplay)
private struct AVPlayerLayerView: UIViewRepresentable {
    let url: URL
    let volume: Float
    
    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.configure(url: url, volume: volume)
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        // No dynamic updates needed for this one-shot video
    }
    
    final class PlayerContainerView: UIView {
        private var player: AVPlayer?
        private var playerLayer: AVPlayerLayer?
        
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        
        func configure(url: URL, volume: Float) {
            let player = AVPlayer(url: url)
            player.actionAtItemEnd = .pause
            player.volume = volume
            (layer as? AVPlayerLayer)?.player = player
            (layer as? AVPlayerLayer)?.videoGravity = .resizeAspect
            self.player = player
            self.playerLayer = layer as? AVPlayerLayer
            player.play()
        }
        
        deinit {
            player?.pause()
        }
    }
}

// MARK: - Phase Indicator View (Removed as requested)