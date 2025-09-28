//
//  CrisisManager.swift
//  Grounded
//
//  Created by Kori Russell on 9/26/25.
//

import Foundation
import AVFoundation
import UIKit
import AudioToolbox

class CrisisManager: NSObject, ObservableObject {
    @Published var isCrisisMode: Bool = false
    @Published var currentHeartRate: Int = 75
    @Published var showCamera: Bool = false
    @Published var crisisDuration: TimeInterval = 0
    @Published var lastAIResponse: String = ""
    @Published var isTTSPlaying: Bool = false
    @Published var arOverlayState = AROverlayState()
    @Published var realTimeARManager = RealTimeARManager()
    @Published var pingARManager = PingARManager()
    @Published var ar3DPingManager = AR3DPingManager()
    @Published var showingBreathingAnchor = false
    @Published var userSpeech: String = ""
    private var isAnyAudioPlaying: Bool = false
    
    // MARK: - Special Requests System
    @Published var isSpecialRequestActive: Bool = false
    @Published var currentSpecialRequest: SpecialRequestType?
    @Published var isBreathingExerciseActive: Bool = false
    @Published var isVideoCallActive: Bool = false
    @Published var breathingPhase: Double = 0.0 // 0.0 = inhale start, 1.0 = exhale start
    
    enum SpecialRequestType {
        case videoCall
        case breathingExercise
    }
    
    // HTTP Polling for Special Requests
    private var specialRequestTimer: Timer?
    private let serverURL = "https://your-server.com/api/special-request/check" // Replace with actual URL
    
    // MARK: - Sequential Two-Phase System
    @Published var currentPhase: CrisisPhase = .computerVision
    @Published var phaseStartTime: Date?
    @Published var cvScanCount: Int = 0
    private var phaseTransitionTimer: Timer?
    
    // Anchor voice timing control
    private var hasPlayedAnchorWelcome: Bool = false
    private var waitingForFirstCameraCapture: Bool = true
    private var voiceInputTimer: Timer?
    var isListeningEnabled: Bool = false
    
    enum CrisisPhase {
        case computerVision  // Phase 1: CV scanning (0-10 seconds)
        case arMode          // Phase 2: AR visualization (10+ seconds)
        
        var description: String {
            switch self {
            case .computerVision:
                return "PHASE 1: CV Scanning"
            case .arMode:
                return "PHASE 2: AR Mode"
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .computerVision:
                return 10.0  // 10 seconds of CV scanning
            case .arMode:
                return Double.infinity  // AR mode continues indefinitely
            }
        }
    }
    
    // Conversational Audio System
    private var currentTTSRequest: String?
    private var pendingTTSRequest: String?
    private var isProcessingTTS: Bool = false
    
    // Request Throttling System
    private var lastTTSRequestTime: Date?
    private var ttsRequestThrottleInterval: TimeInterval = 1.0 // Reduced to 1 second for better responsiveness
    
    // Global Audio Engine Manager
    private var globalAudioEngine: AVAudioEngine?
    private var isAudioEngineActive: Bool = false
    
    
    // Advanced audio management for Base64 playback
    private var mainAudioPlayer: AVAudioPlayer?
    private var thinkingSoundPlayer: AVAudioPlayer?
    private var criticalAudioPlayer: AVAudioPlayer?
    private var isPlayingThinkingSound: Bool = false
    private let serverIP = "100.66.12.253" // Your teammate's server Alex ip 100.66.12.253 my ip is 100.66.8.174
    private let serverPort = "2419" // Your teammate's server port
    // NOTE: For development, add NSAppTransportSecurity settings to Info.plist to allow HTTP connections
    
    // OpenAI TTS Configuration
    private let openAIAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "YOUR_OPENAI_API_KEY_HERE"
    private let openAITTSURL = "https://api.openai.com/v1/audio/speech"
    private var useOpenAITTS: Bool = true // Re-enable OpenAI TTS
    var currentOpenAIVoice: String = "shimmer" // Most calming voice
    private var crisisStartTime: Date?
    private var crisisTimer: Timer?
    private var lastResponseTime: Date?
    
    // Separate streams
    private var textStreamTimer: Timer?
    private var imageStreamTimer: Timer?
    private var conversationActive: Bool = false
    
    // Speech throttling
    private var lastSpeechTime: Date?
    private let speechThrottleInterval: TimeInterval = 0.3 // 0.3 seconds between speech requests
    
    // Conversation management
    private var conversationHistory: [String] = []
    private var lastSentSpeechIndex = 0
    private var conversationContext = ""
    
    // Speech segmentation
    private var currentSpeechBuffer = ""
    private var lastSpeechUpdateTime: Date?
    private let speechSegmentTimeout: TimeInterval = 2.0 // Send after 2 seconds of silence
    private let minSpeechLength = 5 // Minimum characters to send
    private var speechSegmentTimer: Timer?
    private var lastSentSpeech = ""
    
    // Thinking sounds system
    private var thinkingTimer: Timer?
    private let thinkingDelay: TimeInterval = 1.5 // Show thinking after 1.5 seconds (faster)
    private var isProcessingRequest = false
    
    // Pre-generated thinking sound filenames (from bundle)
    private let bundledThinkingSounds = [
        // Short acknowledgments
        "mmm", "umm", "hmm", "uh-huh", "okay", "yes", "right", "i_see",
        
        // Understanding phrases
        "i_understand", "i_hear_you", "that_makes_sense", "im_listening", "go_on", "tell_me_more",
        
        // Processing sounds
        "let_me_think", "one_moment", "im_processing_that", "give_me_a_second",
        
        // Empathetic responses
        "im_here", "youre_safe", "take_your_time", "im_with_you",
        
        // Gentle transitions
        "so", "well", "now", "alright",
        
        // Breathing/calming
        "breathe_with_me", "deep_breath", "in_and_out",
        
        // Soft sounds
        "soft_breath", "gentle_sigh", "quiet_hum"
    ]
    
    // Categorized thinking sounds for different contexts
    private let shortThinkingSounds = ["mmm", "umm", "hmm", "okay", "yes", "right"]
    private let processingThinkingSounds = ["let_me_think", "one_moment", "im_processing_that", "give_me_a_second"]
    private let empathicThinkingSounds = ["im_here", "youre_safe", "take_your_time", "im_with_you"]
    private let breathingThinkingSounds = ["breathe_with_me", "deep_breath", "soft_breath", "gentle_sigh"]
    
    // Dialogue Protocol - isTTSPlaying is now @Published
    private var currentDialoguePhase: DialoguePhase = .initialization
    private var userSpeakingThreshold: Float = 0.1 // Audio level threshold for user speech detection
    
    enum DialoguePhase {
        case initialization
        case stabilization
        case continuousDialogue
        case crisisEnd
    }
    
    override init() {
        super.init()
        setupSpeechSynthesizer()
        simulateHeartRateMonitoring()
        loadBundledThinkingSounds()
        startSpecialRequestPolling()
    }
    
    
    // MARK: - Crisis Protocol (Grounded Voice UX)
    
    func initiateCrisisProtocol() {
        print("🚀 Starting new crisis intervention session")
        
        // Ensure clean state before starting
        endCrisisMode() // This will reset everything
        
        // Wait a moment for cleanup, then start fresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startFreshCrisisSession()
        }
    }
    
    private func startFreshCrisisSession() {
        isCrisisMode = true
        startPhase1ComputerVision()
        crisisStartTime = Date()
        lastResponseTime = Date()
        conversationActive = true
        currentDialoguePhase = .initialization
        
        // Reset first input flag for new session
        isFirstUserInputAfterIntro = true
        shouldEndSession = false
        
        // Reset all state variables for fresh start
        isProcessingTTS = false
        currentTTSRequest = nil
        pendingTTSRequest = nil
        isTTSPlaying = false
        isAnyAudioPlaying = false
        isProcessingRequest = false
        lastSpeechTime = nil
        lastSpeechUpdateTime = nil
        lastSentSpeech = ""
        currentSpeechBuffer = ""
        lastTTSRequestTime = nil
        
        // Reset Anchor voice timing
        hasPlayedAnchorWelcome = false
        waitingForFirstCameraCapture = true
        isListeningEnabled = false
        
        // Real AR detection will be handled by the detection systems
        
        // Start real-time AR detection
        realTimeARManager.startRealTimeDetection()
        
        // Start continuous COCO object detection (silent background tracking)
        pingARManager.startContinuousDetection()
        
        // Notify backend that anxiety session is starting
        notifyBackendAnxietyStart()
        
        // Start crisis duration timer
        crisisTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.crisisStartTime else { return }
            self.crisisDuration = Date().timeIntervalSince(startTime)
            
            // Auto-end crisis after 5 minutes of no AI responses
            if let lastResponse = self.lastResponseTime,
               Date().timeIntervalSince(lastResponse) > 300 { // 5 minutes
                self.endCrisisMode()
            }
        }
        
        // Reset conversation history for new crisis
        resetConversationHistory()
        
        // Reconfigure audio session for new session
        setupSpeechSynthesizer()
        
        // Phase 1: Wait for successful camera capture before playing Anchor voice
        print("🎤 Waiting for successful camera capture before playing Anchor welcome...")
        
        // Phase 2: Start monitoring after stabilization
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.currentDialoguePhase = .stabilization
            self.showCamera = true
            self.startTextConversationStream()
            self.startImageStream()
        }
    }
    
    // MARK: - Hybrid TTS System (OpenAI + Native)
    
    private func speakInitialStabilization() {
        // Play the pre-generated Anchor welcome audio immediately
        playAnchorWelcomeAudio()
    }
    
    // MARK: - Special Requests Methods
    func triggerSpecialRequest(_ type: SpecialRequestType) {
        print("🎬 Triggering special request: \(type)")
        
        // Disable user interactions
        isSpecialRequestActive = true
        currentSpecialRequest = type
        isListeningEnabled = false
        
        switch type {
        case .videoCall:
            startVideoCall()
        case .breathingExercise:
            startBreathingExercise()
        }
    }
    
    private func startVideoCall() {
        print("📹 Starting video call from mom")
        isVideoCallActive = true
        // Ensure user input is not recorded during video overlay
        cameraController?.pauseSpeechRecognition()
        
        // Auto-end after video duration (5 seconds for specialvideo.MOV)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.endVideoCall()
        }
    }
    
    private func endVideoCall() {
        print("📹 Ending video call")
        isVideoCallActive = false
        // Resume speech recognition after video
        cameraController?.resumeSpeechRecognition()
        endSpecialRequest()
    }
    
    private func startBreathingExercise() {
        print("🫁 Starting breathing exercise")
        isBreathingExerciseActive = true
        breathingPhase = 0.0
        
        // Start breathing cycle animation (6 breaths per minute = 10 seconds per cycle)
        startBreathingCycle()
        
        // Breathing exercise duration (2 minutes = 12 cycles at 6 BPM)
        DispatchQueue.main.asyncAfter(deadline: .now() + 120.0) {
            self.endBreathingExercise()
        }
    }
    
    private func startBreathingCycle() {
        // 6 breaths per minute = 10 seconds per cycle (5s inhale, 5s exhale)
        let inhaleDuration: TimeInterval = 5.0
        let exhaleDuration: TimeInterval = 5.0
        
        // Inhale phase - animate to 1.0 over 5 seconds
        animateBreathingPhase(to: 1.0, duration: inhaleDuration) {
            // Exhale phase - animate to 0.0 over 5 seconds
            self.animateBreathingPhase(to: 0.0, duration: exhaleDuration) {
                // Continue cycle if still active
                if self.isBreathingExerciseActive {
                    self.startBreathingCycle()
                }
            }
        }
    }
    
    private func animateBreathingPhase(to targetPhase: Double, duration: TimeInterval, completion: @escaping () -> Void) {
        let startPhase = breathingPhase
        let startTime = Date()
        
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            
            // Ease in-out animation
            let easedProgress = progress < 0.5 ? 
                2 * progress * progress : 
                1 - pow(-2 * progress + 2, 2) / 2
            
            self.breathingPhase = startPhase + (targetPhase - startPhase) * easedProgress
            
            if progress >= 1.0 {
                timer.invalidate()
                completion()
            }
        }
    }
    
    private func endBreathingExercise() {
        print("🫁 Ending breathing exercise")
        isBreathingExerciseActive = false
        endSpecialRequest()
    }
    
    private func endSpecialRequest() {
        print("🎬 Ending special request")
        isSpecialRequestActive = false
        currentSpecialRequest = nil
        
        // Re-enable user interactions after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isListeningEnabled = true
        }
    }
    
    // MARK: - HTTP Polling for Special Requests
    private func startSpecialRequestPolling() {
        print("🔄 Starting special request polling")
        specialRequestTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.checkForSpecialRequests()
        }
    }
    
    private func checkForSpecialRequests() {
        guard !isSpecialRequestActive else { return } // Don't check if already in special request
        
        guard let url = URL(string: serverURL) else {
            print("❌ Invalid server URL: \(serverURL)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Special request check failed: \(error)")
                return
            }
            
            guard let data = data else {
                print("❌ No data received from special request check")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let typeString = json?["type"] as? String
                
                if let typeString = typeString, !typeString.isEmpty {
                    print("🎬 Received special request: \(typeString)")
                    
                    DispatchQueue.main.async {
                        switch typeString {
                        case "videoCall":
                            self.triggerSpecialRequest(.videoCall)
                        case "breathingExercise":
                            self.triggerSpecialRequest(.breathingExercise)
                        default:
                            print("❌ Unknown special request type: \(typeString)")
                        }
                    }
                }
            } catch {
                print("❌ Failed to parse special request response: \(error)")
            }
        }.resume()
    }
    
    deinit {
        specialRequestTimer?.invalidate()
    }
    
    private func playAnchorWelcomeAudio() {
        print("🎤 Playing Anchor welcome audio immediately...")
        
        // CRITICAL: Stop speech recognition before playing anchor audio
        stopSpeechRecognition()
        
        // Try to load the bundled Anchor welcome audio
        guard let audioPath = Bundle.main.path(forResource: "AnchorWelcome", ofType: "mp3") else {
            print("❌ AnchorWelcome.mp3 not found in bundle - using fallback")
            // Fallback to OpenAI TTS if file not found
            let fallbackText = "I'm Anchor. I've notified your close contacts, and they'll reach out soon. Until then, you're not alone — we can try grounding, breathing, or soothing videos. Tell me what feels right, or I can guide you."
            speakWithOpenAI(text: fallbackText, interruptible: false)
            return
        }
        
        do {
            // Stop any current audio
            mainAudioPlayer?.stop()
            
            // Configure audio session for uninterrupted playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try audioSession.setActive(true, options: [])
            print("🔊 Audio session configured for Anchor welcome")
            
            // Create audio player with the bundled file
            let audioURL = URL(fileURLWithPath: audioPath)
            mainAudioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            mainAudioPlayer?.delegate = self
            mainAudioPlayer?.volume = 1.0
            mainAudioPlayer?.numberOfLoops = 0
            mainAudioPlayer?.prepareToPlay()
            
            // Set TTS playing flag to prevent echo
            isTTSPlaying = true
            isListeningEnabled = false
            print("🎤 Speech recognition stopped and listening disabled during Anchor message")
            
            // Play the Anchor welcome audio
            if mainAudioPlayer?.play() == true {
                print("🎵 Playing Anchor welcome audio (\(mainAudioPlayer?.duration ?? 0)s)")
                
                // Enable listening after Anchor message duration (about 11 seconds)
                let anchorDuration = mainAudioPlayer?.duration ?? 11.0
                DispatchQueue.main.asyncAfter(deadline: .now() + anchorDuration) {
                    self.enableListeningAfterAnchor()
                }
            } else {
                print("❌ Failed to play Anchor welcome audio")
                // Enable listening immediately if audio fails
                enableListeningAfterAnchor()
            }
            
        } catch {
            print("❌ Error playing Anchor welcome audio: \(error)")
            // Enable listening immediately if audio fails
            enableListeningAfterAnchor()
        }
    }
    
    private func enableUserResponseAfterAnchor() {
        print("🎤 Anchor message complete - enabling user response!")
        
        // Resume speech recognition for user input
        cameraController?.resumeSpeechRecognition()
        
        // Set dialogue phase to allow user interaction
        currentDialoguePhase = .continuousDialogue
        
        // Clear TTS state
        isTTSPlaying = false
        isProcessingTTS = false
        
        print("✅ User can now speak to the LLM!")
    }
    
    // MARK: - Camera Capture Success Handler
    
    func onSuccessfulCameraCapture() {
        // Only play Anchor welcome on the first successful capture
        guard waitingForFirstCameraCapture && !hasPlayedAnchorWelcome else {
            return
        }
        
        print("📸 First successful camera capture detected - playing Anchor welcome!")
        waitingForFirstCameraCapture = false
        hasPlayedAnchorWelcome = true
        
        // Play Anchor welcome audio immediately after successful camera capture
        playAnchorWelcomeAudio()
    }
    
    private func enableListeningAfterAnchor() {
        print("Anchor message complete - enabling listening!")
        
        // Enable listening flag
        isListeningEnabled = true
        
        // Set dialogue phase to allow user interaction
        currentDialoguePhase = .continuousDialogue
        
        // Clear TTS state
        isTTSPlaying = false
        isProcessingTTS = false
        
        print("User can now speak to the LLM - speech recognition is listening!")
        print("Final state - isListeningEnabled: \(isListeningEnabled), isTTSPlaying: \(isTTSPlaying)")
    }
    
    private func playCriticalAudioFile(_ filename: String, interruptible: Bool = true) {
        guard let audioPath = Bundle.main.path(forResource: filename.replacingOccurrences(of: ".mp3", with: ""), ofType: "mp3") else {
            print("❌ Critical audio file not found: \(filename)")
            // Fallback to native TTS
            let fallbackText = filename.contains("intro") ? 
                "Hello. I am here for you. Take a slow, deep breath. We are starting the grounding protocol now." :
                "You're doing great. The crisis intervention is complete. Take care of yourself."
            speakWithGroundedVoice(fallbackText, interruptible: interruptible)
            return
        }
        
        do {
            let audioURL = URL(fileURLWithPath: audioPath)
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.delegate = self
            
            // Store the critical audio player
            criticalAudioPlayer = player
            
            // Stop any current speech if interruptible
            if interruptible && isTTSPlaying {
                stopAllTTS()
            }
            
            isTTSPlaying = true
            let playResult = player.play()
            
            print("🎤 Playing critical audio: \(filename) (Interruptible: \(interruptible)) - Play result: \(playResult)")
            print("🎤 Critical audio duration: \(player.duration) seconds")
            
            // Add timeout to reset isTTSPlaying if audio doesn't complete
            if playResult && player.duration > 0 {
                let timeout = player.duration + 2.0 // Add 2 seconds buffer
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                    if self.isTTSPlaying && self.criticalAudioPlayer == player {
                        print("⚠️ Critical audio timeout - resetting isTTSPlaying")
                        self.isTTSPlaying = false
                        self.criticalAudioPlayer = nil
                        self.cameraController?.resumeSpeechRecognition()
                        self.processQueuedSpeech()
                    }
                }
            }
            
        } catch {
            print("❌ Failed to play critical audio: \(error)")
            // Fallback to native TTS
            let fallbackText = filename.contains("intro") ? 
                "Hello. I am here for you. Take a slow, deep breath. We are starting the grounding protocol now." :
                "You're doing great. The crisis intervention is complete. Take care of yourself."
            speakWithGroundedVoice(fallbackText, interruptible: interruptible)
        }
    }
    
    private func testAudio() {
        print("🔊 Testing audio...")
        let testUtterance = AVSpeechUtterance(string: "Audio test")
        testUtterance.rate = 0.5
        testUtterance.volume = 1.0
        // Test audio removed - using OpenAI TTS only
    }
    
    // Method to test different voices
    func testVoice(_ voiceId: String) {
        let testText = "Hello, this is a voice test. How do I sound?"
        let utterance = AVSpeechUtterance(string: testText)
        utterance.rate = 0.5
        
        if let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
            print("🎤 Testing native voice: \(voiceId)")
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            print("🎤 Voice not available, using default")
        }
        
        // Voice test removed - using OpenAI TTS only
    }
    
    
    // Method to test OpenAI with different speeds
    func testOpenAIVoiceWithSpeed(_ voice: String, speed: Float) {
        let testText = "Hello, this is an OpenAI voice test. How do I sound?"
        currentOpenAIVoice = voice
        
        // Create custom request with specific speed
        guard let url = URL(string: openAITTSURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "model": "tts-1-hd",
            "input": testText,
            "voice": voice,
            "response_format": "mp3",
            "speed": speed
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    if let data = data {
                        self?.playOpenAIAudio(data: data, interruptible: true)
                    }
                }
            }.resume()
            
        } catch {
            print("❌ Failed to create OpenAI request: \(error)")
        }
    }
    
    // Test calming conversation for panic attack intervention
    func testCalmingConversation() {
        let calmingText = "Hello, I'm here to help you. Take a slow, deep breath with me. In... and out. You're safe right now. Let's focus on what you can see around you. Can you tell me about something you notice in your environment?"
        speakWithOpenAI(text: calmingText, interruptible: true)
    }
    
    
    // Simple OpenAI test without speech recognition conflicts
    func testSimpleOpenAI() {
        let testText = "Hello, this is a simple OpenAI voice test. Can you hear me clearly?"
        speakWithOpenAI(text: testText, interruptible: true)
    }
    
    // Alternative test using native TTS first to verify audio works
    func testNativeAudio() {
        let testText = "Testing native audio. Can you hear this clearly?"
        speakWithNativeTTS(text: testText, interruptible: true)
    }
    
    // Test with a simple system sound first
    func testSystemSound() {
        AudioServicesPlaySystemSound(1007) // SMS sound
        print("🔊 Played system sound")
    }
    
    // Test audio session state
    func testAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        print("🔊 Audio session category: \(audioSession.category)")
        print("🔊 Audio session mode: \(audioSession.mode)")
        print("🔊 Audio session is active: \(audioSession.isOtherAudioPlaying)")
        print("🔊 Audio session current route: \(audioSession.currentRoute)")
        
        // Try to force audio to speakers
        do {
            try audioSession.setActive(false)
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("🔊 Audio session forced to speakers")
            print("🔊 Audio session now active: \(audioSession.isOtherAudioPlaying)")
        } catch {
            print("❌ Failed to set audio session: \(error)")
        }
    }
    
    // Test device audio with a simple beep
    func testDeviceAudio() {
        // Play a simple beep sound
        let beepSound: SystemSoundID = 1005 // SMS sound
        AudioServicesPlaySystemSound(beepSound)
        print("🔊 Played beep sound")
        
        // Also try playing a simple tone
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let toneSound: SystemSoundID = 1006 // SMS sound
            AudioServicesPlaySystemSound(toneSound)
            print("🔊 Played tone sound")
        }
    }
    
    // Test Zoe specifically with optimized settings
    func testZoeVoice() {
        let testText = "Hello, this is Zoe speaking. I should sound very natural and calming, perfect for helping during difficult moments."
        let utterance = AVSpeechUtterance(string: testText)
        
        // Optimized settings for Zoe
        utterance.rate = 0.38           // Slower for natural pacing
        utterance.volume = 1.0         // Full volume
        utterance.pitchMultiplier = 0.92  // Slightly lower pitch for warmth
        utterance.preUtteranceDelay = 0.15
        utterance.postUtteranceDelay = 0.15
        
        // Find the actual Zoe voice
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let zoeVoices = voices.filter { voice in
            voice.name.lowercased().contains("zoe")
        }
        
        if let zoeVoice = zoeVoices.first {
            utterance.voice = zoeVoice
            print("🎤 Using Zoe voice: \(zoeVoice.name)")
            print("🎤 Zoe identifier: \(zoeVoice.identifier)")
            print("🎤 Zoe quality: \(zoeVoice.quality.rawValue)")
        } else {
            // Try common Zoe identifiers
            let zoeIdentifiers = [
                "com.apple.ttsbundle.Zoe-compact",
                "com.apple.ttsbundle.Zoe-premium",
                "com.apple.voice.compact.en-US.Zoe"
            ]
            
            var foundZoe = false
            for identifier in zoeIdentifiers {
                if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                    utterance.voice = voice
                    print("🎤 Using Zoe voice: \(voice.name)")
                    print("🎤 Zoe identifier: \(identifier)")
                    foundZoe = true
                    break
                }
            }
            
            if !foundZoe {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                print("❌ Zoe not found, using default")
            }
        }
        
        // Voice test removed - using OpenAI TTS only
    }
    
    // Test all Zoe voices to find the right one
    func testAllZoeVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let zoeVoices = voices.filter { voice in
            voice.name.lowercased().contains("zoe")
        }
        
        if zoeVoices.isEmpty {
            print("❌ No Zoe voices found")
            return
        }
        
        print("🎤 Found \(zoeVoices.count) Zoe voice(s)")
        
        for (index, zoeVoice) in zoeVoices.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 3.0) {
                let testText = "Hello, this is Zoe voice number \(index + 1). My identifier is \(zoeVoice.identifier)."
                let utterance = AVSpeechUtterance(string: testText)
                utterance.voice = zoeVoice
                utterance.rate = 0.4
                // Voice test removed - using OpenAI TTS only
                print("🎤 Testing Zoe \(index + 1): \(zoeVoice.name) - \(zoeVoice.identifier)")
            }
        }
    }
    
    // Test premium voice with optimized settings
    func testPremiumVoice() {
        let testText = "Hello, this is a premium voice test with optimized settings. I should sound very natural and calming."
        let utterance = AVSpeechUtterance(string: testText)
        
        // Premium settings for natural sound
        utterance.rate = 0.35           // Much slower for natural pacing
        utterance.volume = 1.0         // Full volume
        utterance.pitchMultiplier = 0.9  // Lower pitch for warmth
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        // Use the best available voices from your device (including downloaded Zoe)
        let bestVoices = [
            "com.apple.ttsbundle.Zoe-compact",          // Zoe - downloaded enhanced version
            "com.apple.ttsbundle.Zoe-premium",          // Zoe - premium version if available
            "com.apple.voice.compact.en-US.Samantha",   // Samantha - good quality
            "com.apple.ttsbundle.siri_nicky_en-US_compact",  // Nicky - Siri voice
            "com.apple.ttsbundle.siri_aaron_en-US_compact",  // Aaron - Siri voice
            "com.apple.voice.compact.en-GB.Daniel",     // Daniel - British
            "com.apple.voice.compact.en-AU.Karen"       // Karen - Australian
        ]
        
        var foundGoodVoice = false
        for voiceId in bestVoices {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
                utterance.voice = voice
                print("🎤 Using best available voice: \(voice.name)")
                print("🎤 Voice identifier: \(voiceId)")
                print("🎤 Voice quality: \(voice.quality.rawValue)")
                foundGoodVoice = true
                break
            }
        }
        
        if !foundGoodVoice {
            // Fallback to any English voice
            let englishVoices = AVSpeechSynthesisVoice.speechVoices().filter { voice in
                voice.language.hasPrefix("en")
            }
            
            if let englishVoice = englishVoices.first {
                utterance.voice = englishVoice
                print("🎤 Using English voice: \(englishVoice.name)")
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                print("❌ Using default voice")
            }
        }
        
        // Voice test removed - using OpenAI TTS only
    }
    
    // List all available voices for debugging
    func listAllVoices() {
        print("🎤 Available voices:")
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for voice in voices {
            print("🎤 \(voice.name) - \(voice.identifier) - Quality: \(voice.quality.rawValue)")
        }
        
        // Specifically look for Zoe voices
        print("\n🔍 Looking for Zoe voices:")
        let zoeVoices = voices.filter { voice in
            voice.name.lowercased().contains("zoe")
        }
        
        if zoeVoices.isEmpty {
            print("❌ No Zoe voices found")
        } else {
            for zoeVoice in zoeVoices {
                print("✅ Found Zoe: \(zoeVoice.name) - \(zoeVoice.identifier) - Quality: \(zoeVoice.quality.rawValue)")
            }
        }
    }
    
    // Test ElevenLabs TTS (Best Quality)
    func testElevenLabsTTS() {
        let testText = "Hello, this is ElevenLabs TTS. I should sound very natural and human-like, perfect for helping during difficult moments."
        
        // ElevenLabs API - Get free API key from elevenlabs.io
        let elevenLabsAPIKey = "YOUR_ELEVENLABS_API_KEY" // Replace with your free API key
        let elevenLabsURL = "https://api.elevenlabs.io/v1/text-to-speech/pNInz6obpgDQGcFmaJgB/stream"
        
        if elevenLabsAPIKey == "YOUR_ELEVENLABS_API_KEY" {
            print("❌ ElevenLabs API key not set")
            print("🔑 Get free API key from: https://elevenlabs.io")
            print("💡 Free tier: 10,000 characters/month")
            return
        }
        
        var request = URLRequest(url: URL(string: elevenLabsURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
        
        let requestBody = [
            "text": testText,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.5
            ]
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data {
                    // Play the audio data
                    DispatchQueue.main.async {
                        self.playAudioData(data)
                    }
                }
            }.resume()
            
        } catch {
            print("❌ ElevenLabs request failed: \(error)")
        }
    }
    
    private func playAudioData(_ data: Data) {
        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tts_\(UUID().uuidString).mp3")
            try data.write(to: tempURL)
            
            let player = try AVAudioPlayer(contentsOf: tempURL)
            player.play()
            print("🎤 Playing cloud TTS audio")
            
        } catch {
            print("❌ Failed to play audio: \(error)")
        }
    }
    
    // Old speakWithGroundedVoice function removed - using simplified version below
    
    // Process conversational TTS - prioritizes most recent response
    private func processConversationalTTS(_ text: String) {
        print("🎤 Processing conversational TTS: '\(text)'")
        
        // Stop ALL current speech before starting new one
        stopAllTTS()
        
        // Set processing flags
        isProcessingTTS = true
        currentTTSRequest = text
        isAnyAudioPlaying = true
        
        // Pause speech recognition to prevent feedback
        pauseSpeechRecognition()
        
        // Choose TTS method based on configuration
        if useOpenAITTS && !text.isEmpty {
            speakWithOpenAI(text: text, interruptible: true)
            // Call completion after a delay (since we can't get actual completion)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.count) * 0.08) {
                self.onConversationalAudioCompleted()
            }
        } else {
            speakWithNativeTTS(text: text, interruptible: true) { [weak self] in
                self?.onConversationalAudioCompleted()
            }
        }
    }
    
    // Called when conversational audio completes
    private func onConversationalAudioCompleted() {
        print("🎤 Conversational audio completed")
        
        // Reset flags
        isTTSPlaying = false
        isAnyAudioPlaying = false
        isProcessingTTS = false
        currentTTSRequest = nil
        
        // Resume speech recognition
        resumeSpeechRecognition()
        
        // Check if there's a pending TTS request (newer, more relevant)
        if let pending = pendingTTSRequest {
            print("🔄 Processing pending TTS: '\(pending)'")
            pendingTTSRequest = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.processConversationalTTS(pending)
            }
        } else {
            print("🎤 No pending TTS - conversation complete")
        }
    }
    
    // Stop all TTS instances
    private func stopAllTTS() {
        // Stop OpenAI TTS only
        isTTSPlaying = false
        isAnyAudioPlaying = false
        
        // Stop any audio players
        mainAudioPlayer?.stop()
        thinkingSoundPlayer?.stop()
        
        // Stop any thinking timers
        stopThinkingTimer()
        
        // Clear any pending TTS requests
        lastResponseTime = nil
        
        // Set processing flag to false to prevent thinking sounds
        isProcessingRequest = false
        
        // Reset conversational TTS system
        currentTTSRequest = nil
        pendingTTSRequest = nil
        isProcessingTTS = false
        
        // Reset global audio engine
        if let audioEngine = globalAudioEngine {
            audioEngine.stop()
            globalAudioEngine = nil
        }
        isAudioEngineActive = false
        
        print("🛑 Stopped all TTS instances and timers")
    }
    
    private func speakWithOpenAI(text: String, interruptible: Bool = true) {
        print("🎤 OpenAI TTS Request: '\(text)'")
        print("🔑 API Key: \(openAIAPIKey.prefix(10))...")
        print("🌐 URL: \(openAITTSURL)")
        let startTime = Date()
        
        // Stop thinking sound now that we're about to play TTS
        stopThinkingSound()
        
        
        // Check if API key is set
        if openAIAPIKey == "YOUR_OPENAI_API_KEY_HERE" {
            print("❌ OpenAI API key not set! Please update CrisisManager.swift line 26")
            speakWithNativeTTS(text: text, interruptible: interruptible)
            return
        }
        
        // Prepare API request
        guard let url = URL(string: openAITTSURL) else {
            print("❌ Invalid OpenAI TTS URL")
            speakWithNativeTTS(text: text, interruptible: interruptible)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "model": "tts-1-hd",
            "input": text,
            "voice": currentOpenAIVoice,
            "response_format": "mp3",
            "speed": 1.0  // Normal speed for calming effect
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to create OpenAI request: \(error)")
            speakWithNativeTTS(text: text, interruptible: interruptible)
            return
        }
        
        // Make API call
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                let apiTime = Date().timeIntervalSince(startTime)
                print("⏱️ OpenAI API call took: \(String(format: "%.2f", apiTime))s")
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        print("❌ HTTP Error: \(httpResponse.statusCode)")
                        if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                            print("📝 Error details: \(errorMessage)")
                        }
                        print("❌ OpenAI TTS HTTP Error - no fallback")
                        return
                    }
                }
                
                if let error = error {
                    print("❌ OpenAI TTS failed: \(error.localizedDescription)")
                    print("❌ No fallback - OpenAI TTS only")
                    return
                }
                
                guard let data = data else {
                    print("❌ No OpenAI TTS data received")
                    print("❌ No fallback - OpenAI TTS only")
                    return
                }
                
                print("✅ Received \(data.count) bytes of audio data")
                
                // Play the OpenAI audio
                self?.playOpenAIAudio(data: data, interruptible: interruptible)
            }
        }.resume()
    }
    
    private func playOpenAIAudio(data: Data, interruptible: Bool) {
        do {
            // Save audio file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("openai_tts_\(UUID().uuidString).mp3")
            try data.write(to: tempURL)
            print("💾 Saved OpenAI audio to: \(tempURL.path)")
            
            // Use AVAudioEngine for more reliable playback
            let audioEngine = AVAudioEngine()
            let playerNode = AVAudioPlayerNode()
            let audioFile = try AVAudioFile(forReading: tempURL)
            
            // Ensure only one audio engine is active at a time
            guard !isAudioEngineActive else {
                print("🚫 Audio engine already active - skipping TTS request")
                return
            }
            
            // Set global audio engine
            globalAudioEngine = audioEngine
            isAudioEngineActive = true
            
            // Configure audio engine
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)
            
            // Start audio engine
            try audioEngine.start()
            print("🔊 AVAudioEngine started")
            
            isTTSPlaying = true
            
            // Schedule and play the audio file
            playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.isTTSPlaying = false
                    self?.isAnyAudioPlaying = false
                    self?.isAudioEngineActive = false
                    self?.globalAudioEngine = nil
                    print("🎤 OpenAI audio finished playing via AVAudioEngine")
                    
                    // Stop audio engine
                    audioEngine.stop()
                    
                    // Restart speech recognition after TTS completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.restartSpeechRecognition()
                        print("🔊 Speech recognition restarted after OpenAI TTS completion")
                        
                        // Process any queued speech after AI finishes
                        self?.processQueuedSpeech()
                    }
                }
            }
            
            playerNode.play()
            print("🎤 Playing OpenAI TTS via AVAudioEngine")
            print("🔊 Audio file duration: \(audioFile.length) samples")
            
            // Ensure audio session is properly configured for playback
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
                try audioSession.setActive(true)
                print("✅ Audio session activated for TTS playback")
            } catch {
                print("⚠️ Could not activate audio session: \(error)")
            }
            
            // File cleanup is now handled in completion callback
            
        } catch {
            print("❌ Failed to play OpenAI audio: \(error)")
            isTTSPlaying = false
            
            // Resume speech recognition on error
            resumeSpeechRecognition()
        }
    }
    
    private func speakWithNativeTTS(text: String, interruptible: Bool = true, completion: (() -> Void)? = nil) {
        let utterance = AVSpeechUtterance(string: text)
        
        // Optimized settings for premium quality
        utterance.rate = 0.45        // Slower for more natural pacing
        utterance.volume = 1.0       // Full volume
        utterance.pitchMultiplier = 1.0  // Natural pitch
        
        // Premium Neural Voices (Zoe First - Downloaded Enhanced Version)
        let voiceOptions = [
            "com.apple.ttsbundle.Zoe-compact",          // Zoe - Downloaded enhanced version
            "com.apple.ttsbundle.Zoe-premium",          // Zoe - Premium version if available
            "com.apple.voice.compact.en-US.Samantha",   // Samantha - Good quality
            "com.apple.ttsbundle.siri_nicky_en-US_compact",  // Nicky - Siri voice
            "com.apple.ttsbundle.siri_aaron_en-US_compact",  // Aaron - Siri voice
            "com.apple.voice.compact.en-GB.Daniel",     // Daniel - British
            "com.apple.voice.compact.en-AU.Karen"       // Karen - Australian
        ]
        
        // Try voices in order of preference
        for voiceId in voiceOptions {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
                utterance.voice = voice
                print("🎤 Using voice: \(voiceId)")
                break
            }
        }
        
        // Fallback to default if none work
        if utterance.voice == nil {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            print("🎤 Using default voice")
        }
        
        // Set up completion handler
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        isTTSPlaying = true
        
        // Stop speech recognition during TTS to prevent feedback
        stopSpeechRecognition()
        
        // Voice test removed - using OpenAI TTS only
        
        print("🎤 Grounded Voice: '\(text)' (Interruptible: \(interruptible))")
        
        // Speech recognition will be resumed by audioPlayerDidFinishPlaying callback
        // This ensures proper timing based on actual audio completion
    }
    
    func pauseSpeechRecognition() {
        cameraController?.pauseSpeechRecognition()
        
        // Clear similarity tracking when AI starts speaking to prevent mixed audio comparisons
        lastSentSpeech = ""
        
        print("⏸️ Speech recognition paused and similarity buffer cleared for TTS")
        
        // Add a small delay to ensure speech recognition is fully paused
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Additional pause confirmation
        }
    }
    
    func resumeSpeechRecognition() {
        cameraController?.resumeSpeechRecognition()
        print("▶️ Speech recognition resumed after TTS")
        
        // Add a small delay to ensure speech recognition is fully resumed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Additional resume confirmation
        }
    }
    
    // Process any queued speech after AI finishes speaking
    private func processQueuedSpeech() {
        // Check if there's any pending speech from the camera controller
        if let cameraController = cameraController, !cameraController.pendingSpeechText.isEmpty {
            let queuedSpeech = cameraController.pendingSpeechText
            print("🔄 Processing queued speech after AI completion: '\(queuedSpeech)'")
            
            // Clear the queued speech first
            cameraController.pendingSpeechText = ""
            
            // Process the queued speech immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("Processing queued user speech: '\(queuedSpeech)'")
                print("Speech length: \(queuedSpeech.count) characters")
                self.processSpeechText(queuedSpeech)
            }
        } else {
            print("🔄 No queued speech to process")
        }
    }
    
    func stopSpeechRecognition() {
        // Completely stop speech recognition during TTS
        if let cameraController = cameraController {
            cameraController.audioEngine?.stop()
            cameraController.recognitionRequest?.endAudio()
            cameraController.recognitionTask?.cancel()
            print("🛑 Speech recognition completely stopped for TTS")
        }
    }
    
    func restartSpeechRecognition() {
        // Restart speech recognition after TTS
        if let cameraController = cameraController {
            cameraController.startSpeechRecognition()
            print("🔄 Speech recognition restarted after TTS")
        }
    }
    
    // Reference to camera controller for speech control
    weak var cameraController: ContinuousCameraViewController?
    
    func stopTTSImmediately() {
        if isTTSPlaying {
            // Stop OpenAI TTS and audio player
            stopAllTTS()
            stopThinkingSound() // Also stop thinking sound
            isTTSPlaying = false
            print("🛑 All audio stopped immediately - user is speaking")
        }
    }
    
    // Better TTS management with completion tracking
    private func speakWithGroundedVoice(_ text: String, interruptible: Bool = true) {
        // If already speaking, stop and replace (no queuing to prevent overlap)
        if isTTSPlaying {
            print("🎤 Stopping current TTS to speak new response")
            stopTTSImmediately()
            // Small delay to ensure previous TTS stops completely
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.startNewTTS(text, interruptible: interruptible)
            }
        } else {
            startNewTTS(text, interruptible: interruptible)
        }
    }
    
    private func startNewTTS(_ text: String, interruptible: Bool) {
        // ONLY use OpenAI TTS - no native fallback
        speakWithOpenAI(text: text, interruptible: interruptible)
    }
    
    
    // MARK: - Simple Text Conversation Management
    
    private func startTextConversationStream() {
        print("💬 Starting simplified text conversation stream...")
        
        // No automatic initial prompt - wait for user to speak first
        currentDialoguePhase = .continuousDialogue
        print("💬 Conversation is user-driven - waiting for first user input (no automatic prompts)")
    }
    
    private func startImageStream() {
        print("📸 Starting image stream for visual context...")
        
        // Start image capture every 5 seconds for visual context
        imageStreamTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, self.conversationActive else { return }
            
            // Trigger image capture from camera controller
            if let cameraController = self.cameraController {
                print("📸 Triggering camera capture from timer...")
                cameraController.captureAndSendImage()
            } else {
                print("❌ Camera controller is nil - cannot capture real images!")
            }
        }
        
        print("📸 Image stream started - capturing every 5 seconds for visual context")
    }
    
    // MARK: - Image Capture and Processing
    
    func processCapturedImage(_ image: UIImage) {
        print("📸 Processing captured image for visual context...")
        
        // OPTIMIZE: Resize image to reasonable size before compression
        let targetSize = CGSize(width: 640, height: 480)
        let resizedImage = resizeImage(image: image, targetSize: targetSize)
        
        // OPTIMIZE: Use higher compression for faster transmission
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.3) else {
            print("❌ Failed to convert image to JPEG data")
            return
        }
        
        let imageBase64 = imageData.base64EncodedString()
        print("📸 Image optimized and converted to base64: \(imageBase64.count) characters (was \(image.size.width)x\(image.size.height), now \(resizedImage.size.width)x\(resizedImage.size.height))")
        
        // Send optimized image to backend
        sendImageToAI(imageBase64: imageBase64)
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    // MARK: - Session End Detection
    @Published var shouldEndSession: Bool = false
    
    // MARK: - First Input Tracking
    private var isFirstUserInputAfterIntro: Bool = true
    
    // MARK: - Goodbye Audio
    private func playGoodbyeAudio() {
        print("👋 Playing goodbye audio...")
        
        // Try to load the bundled goodbye audio
        guard let audioPath = Bundle.main.path(forResource: "goodbye", ofType: "mp3") else {
            print("❌ goodbye.mp3 not found in bundle - ending session without audio")
            endCrisisMode()
            return
        }
        
        do {
            // Stop any current audio
            mainAudioPlayer?.stop()
            
            // Configure audio session for uninterrupted playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            // Create audio player
            let audioURL = URL(fileURLWithPath: audioPath)
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.delegate = self
            player.prepareToPlay()
            
            // Store the goodbye audio player
            mainAudioPlayer = player
            
            // Set TTS playing flag to prevent echo
            isTTSPlaying = true
            isListeningEnabled = false
            print("👋 Speech recognition stopped during goodbye message")
            
            // Play the goodbye audio
            if player.play() {
                print("✅ Goodbye audio started playing")
            } else {
                print("❌ Failed to play goodbye audio")
                endCrisisMode()
            }
            
        } catch {
            print("❌ Error playing goodbye audio: \(error)")
            endCrisisMode()
        }
    }
    
    // MARK: - Simplified Network Communication (Text Only)
    
    // Notify backend that anxiety session is starting
    private func notifyBackendAnxietyStart() {
        let url = URL(string: "http://\(serverIP):\(serverPort)/start-new-anxiety")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Simple payload to indicate session start
        let payload = [
            "timestamp": Date().timeIntervalSince1970,
            "session_id": UUID().uuidString
        ] as [String: Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            print("🚀 Notifying backend: new anxiety session starting (POST /start-new-anxiety)")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to notify backend of anxiety start: \(error.localizedDescription)")
                    } else if let httpResponse = response as? HTTPURLResponse {
                        print("✅ Backend notified of anxiety start - Status: \(httpResponse.statusCode)")
                    }
                }
            }.resume()
            
        } catch {
            print("❌ Failed to encode start_anxiety payload: \(error.localizedDescription)")
        }
    }
    
    // Advanced function for text communication with Base64 audio response
    private func sendSimpleTextToAI(_ text: String) {
        // Start thinking sound immediately
        startThinkingSound()
        
        let url = URL(string: "http://\(serverIP):\(serverPort)/upload_text")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Request Base64 audio response
        let payload = [
            "text": text,
            "heart_rate": Float(currentHeartRate),  // Convert Int to Float
            "timestamp": Date().timeIntervalSince1970,
            "response_format": "audio_base64" // Request audio instead of text
        ] as [String : Any]
        
        print("💬 ADVANCED TEXT REQUEST (Audio Response):")
        print("📍 URL: \(url)")
        print("📝 Text: \(text)")
        print("🎵 Thinking sound started")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            print("✅ Advanced text request created")
        } catch {
            print("❌ Failed to create advanced text request: \(error)")
            stopThinkingSound()
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // Let thinking sound finish naturally - don't stop immediately
                // It will stop when the actual TTS starts playing
                
                if let error = error {
                    print("❌ Advanced text request failed: \(error.localizedDescription)")
                    self?.speakFallbackInstructions()
                    return
                }
                
                guard let data = data else {
                    print("❌ No response data")
                    self?.speakFallbackInstructions()
                    return
                }
                
                print("✅ Advanced response received: \(data.count) bytes")
                self?.processAdvancedResponse(data)
            }
        }.resume()
    }
    
    // Legacy function kept for backward compatibility
    private func sendTextToAI(_ text: String) {
        // Start thinking timer for initial crisis setup
        startThinkingTimer()
        
        let url = URL(string: "http://\(serverIP):\(serverPort)/upload_text")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "text": text,
            "heart_rate": currentHeartRate,
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        // 🔍 DEBUG: Show text request details
        print("💬 TEXT STREAM REQUEST:")
        print("📍 URL: \(url)")
        print("📝 Text: \(text)")
        print("📊 Heart Rate: \(currentHeartRate) BPM")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            print("✅ Text request body created")
        } catch {
            print("❌ Failed to create text request: \(error)")
            stopThinkingTimer()
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // Stop thinking timer when response arrives
                self?.stopThinkingTimer()
                
                if let error = error {
                    print("❌ Text request failed: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("❌ No text response data")
                    return
                }
                
                print("✅ Text response received: \(data.count) bytes")
                self?.processTextResponse(data)
            }
        }.resume()
    }
    
    // Check if AI response is relevant to user input
    private func isResponseRelevant(_ response: String) -> Bool {
        // Check if response contains generic phrases that don't address user input
        let genericPhrases = [
            "Take a deep breath",
            "focus on your breath",
            "grounding yourself",
            "you are safe",
            "inhale through your nose",
            "exhale through your mouth"
        ]
        
        // If response is mostly generic phrases, it's not relevant
        let genericCount = genericPhrases.filter { response.lowercased().contains($0.lowercased()) }.count
        let isGeneric = genericCount >= 2 // Allow some generic phrases but not too many
        
        // Check if response addresses specific user concerns
        let userConcerns = [
            "did not", "can't", "won't", "don't", "stop", "help", "confused", "overwhelmed"
        ]
        
        let addressesConcern = userConcerns.contains { concern in
            conversationHistory.last?.lowercased().contains(concern) == true &&
            response.lowercased().contains(concern)
        }
        
        return !isGeneric || addressesConcern
    }
    
    // Build conversation context from recent history
    private func buildConversationContext() -> String {
        // Build context from recent conversation history (last 3 exchanges)
        let recentHistory = conversationHistory.suffix(3)
        let context = recentHistory.joined(separator: " | ")
        return context
    }
    
    // Send only new user speech to AI (conversational approach)
    private func sendNewSpeechToAI(_ newSpeech: String) {
        // Start thinking timer
        startThinkingTimer()
        
        let url = URL(string: "http://\(serverIP):\(serverPort)/upload_text")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build conversation context for better AI responses
        let conversationContext = buildConversationContext()
        
        // Send new speech with conversation context for better responses
        // Note: FastAPI server expects 'text' field, not 'user_input'
        let payload = [
            "text": newSpeech,
            "conversation_context": conversationContext,
            "heart_rate": Float(currentHeartRate),  // Convert Int to Float
            "timestamp": Date().timeIntervalSince1970,
            "conversation_turn": conversationHistory.count
        ] as [String : Any]
        
        // 🔍 DEBUG: Show new speech request details
        print("💬 NEW SPEECH REQUEST:")
        print("📍 URL: \(url)")
        print("📝 New Text Input: '\(newSpeech)'")
        print("📊 Heart Rate: \(currentHeartRate) BPM")
        print("🔄 Turn: \(conversationHistory.count)")
        
        // Add conversation context to debug output
        if !conversationContext.isEmpty {
            print("💬 Conversation Context: \(conversationContext)")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            print("✅ New speech request body created")
        } catch {
            print("❌ Failed to create new speech request: \(error)")
            stopThinkingTimer()
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // Stop thinking timer when response arrives
                self?.stopThinkingTimer()
                
                if let error = error {
                    print("❌ New speech request failed: \(error.localizedDescription)")
                    self?.isProcessingRequest = false
                    return
                }
                
                guard let data = data else {
                    print("❌ No new speech response data")
                    self?.isProcessingRequest = false
                    return
                }
                
                print("✅ New speech response received: \(data.count) bytes")
                self?.processTextResponse(data)
            }
        }.resume()
    }
    
    // Start thinking timer
    private func startThinkingTimer() {
        // DISABLED: Thinking sounds are turned off
        print("🧠 Thinking timer disabled - skipping")
        return
    }
    
    // Stop thinking timer
    private func stopThinkingTimer() {
        thinkingTimer?.invalidate()
        thinkingTimer = nil
        isProcessingRequest = false
        print("🧠 Thinking timer stopped")
    }
    
    // Play thinking sound
    private func playThinkingSound() {
        guard isProcessingRequest else { 
            print("🧠 Skipping thinking sound - not processing request")
            return 
        }
        
        // Don't play thinking sound if main TTS is playing
        guard !isTTSPlaying else {
            print("🧠 Skipping thinking sound - main TTS is playing")
            return
        }
        
        // Don't play if already playing a thinking sound
        guard !isPlayingThinkingSound else {
            print("🧠 Skipping thinking sound - already playing thinking sound")
            return
        }
        
        // Choose appropriate thinking sound based on context
        let soundCategory = chooseBestThinkingSoundCategory()
        let randomSound = soundCategory.randomElement() ?? "umm"
        
        print("🧠 Playing bundled thinking sound: '\(randomSound)'")
        
        // Play bundled thinking sound
        playBundledThinkingSound(filename: randomSound)
    }
    
    // Choose the best thinking sound category based on context
    private func chooseBestThinkingSoundCategory() -> [String] {
        // If user seems distressed, use empathetic sounds
        if currentHeartRate > 100 {
            return empathicThinkingSounds
        }
        
        // If it's been a longer processing time, use processing sounds
        if let lastResponse = lastResponseTime,
           Date().timeIntervalSince(lastResponse) > 5.0 {
            return processingThinkingSounds
        }
        
        // For breathing exercises or calm moments, use breathing sounds
        if currentHeartRate < 80 {
            return breathingThinkingSounds
        }
        
        // Default to short acknowledgments
        return shortThinkingSounds
    }
    
    // Play bundled thinking sound file
    private func playBundledThinkingSound(filename: String) {
        guard let soundURL = findThinkingSoundURL(basename: filename) else {
            print("❌ Bundled thinking sound not found: \(filename).mp3 - using fallback")
            playFallbackThinkingSound()
            return
        }
        
        do {
            // Stop any existing thinking sound
            thinkingSoundPlayer?.stop()
            
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.delegate = self
            player.volume = 0.7 // Slightly softer for thinking sounds
            
            thinkingSoundPlayer = player
            isPlayingThinkingSound = true
            
            // Pause speech recognition during thinking sound (resume on completion)
            pauseSpeechRecognition()
            
            player.play()
            print("🧠 Playing bundled thinking sound: \(soundURL.lastPathComponent)")
            
        } catch {
            print("❌ Failed to play bundled thinking sound: \(error) - using fallback")
            playFallbackThinkingSound()
        }
    }
    
    // Fallback thinking sound using native TTS
    private func playFallbackThinkingSound() {
        let fallbackSounds = ["Hmm", "Let me think", "I'm processing that", "One moment"]
        let randomSound = fallbackSounds.randomElement() ?? "Hmm"
        
        print("🧠 Playing fallback thinking sound: '\(randomSound)'")
        
        // Use native TTS for thinking sounds
        speakWithNativeTTS(text: randomSound, interruptible: false) {
            self.isPlayingThinkingSound = false
            self.resumeSpeechRecognition()
        }
    }

    // Resilient lookup: try subdirectory, then root, then path-based resolution
    private func findThinkingSoundURL(basename: String) -> URL? {
        let bundle = Bundle.main
        
        // Debug: List all available resources
        if let resourcePath = bundle.resourcePath {
            let thinkingSoundsPath = "\(resourcePath)/AudioFiles/thinking_sounds"
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: thinkingSoundsPath) {
                do {
                    let files = try fileManager.contentsOfDirectory(atPath: thinkingSoundsPath)
                    print("🧠 Available thinking sounds: \(files)")
        } catch {
                    print("❌ Error listing thinking sounds directory: \(error)")
                }
            } else {
                print("❌ Thinking sounds directory not found at: \(thinkingSoundsPath)")
            }
        }
        
        // 1) Try declared subdirectory layout
        if let url = bundle.url(forResource: basename, withExtension: "mp3", subdirectory: "AudioFiles/thinking_sounds") {
            print("✅ Found thinking sound in subdirectory: \(url)")
            return url
        }
        
        // 2) Try at bundle root (Xcode often flattens resource folders)
        if let url = bundle.url(forResource: basename, withExtension: "mp3") {
            print("✅ Found thinking sound at bundle root: \(url)")
            return url
        }
        
        // 3) Try path(forResource:) fallbacks
        if let path = bundle.path(forResource: basename, ofType: "mp3") {
            print("✅ Found thinking sound via path: \(path)")
            return URL(fileURLWithPath: path)
        }
        
        // 4) Try replacing dashes/underscores just in case of rename
        let alt = basename.replacingOccurrences(of: "-", with: "_")
        if alt != basename {
            if let url = bundle.url(forResource: alt, withExtension: "mp3") {
                print("✅ Found thinking sound with alt name: \(url)")
                return url
            }
        }
        
        print("❌ Thinking sound not found: \(basename).mp3")
        return nil
    }
    
    // No longer needed - using bundled thinking sounds
    func downloadThinkingSounds() {
        print("🧠 Using bundled thinking sounds - no download needed!")
        print("✅ All \(bundledThinkingSounds.count) thinking sounds are ready instantly!")
    }
    
    // Check if thinking sounds are available (always true for bundled sounds)
    func areThinkingSoundsDownloaded() -> Bool {
        return true // Bundled sounds are always available
    }
    
    // No cache to clear - using bundled sounds
    func clearThinkingSoundsCache() {
        print("🧠 No cache to clear - using bundled thinking sounds!")
    }
    
    // Load existing thinking sounds cache
    private func loadBundledThinkingSounds() {
        print("🧠 Loading bundled thinking sounds...")
        
        // Debug: List all available resources first (only if files are missing)
        if let resourcePath = Bundle.main.resourcePath {
            let thinkingSoundsPath = "\(resourcePath)/AudioFiles/thinking_sounds"
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: thinkingSoundsPath) {
                print("❌ Thinking sounds directory not found at: \(thinkingSoundsPath)")
                print("🔍 Resource path: \(resourcePath)")
            }
        }
        
        var foundCount = 0
        var missingCount = 0
        
        // Check which bundled thinking sounds are available
        for soundName in bundledThinkingSounds {
            // Try multiple lookup methods like findThinkingSoundURL
            var found = false
            
            // 1) Try subdirectory
            if let _ = Bundle.main.url(forResource: soundName, withExtension: "mp3", subdirectory: "AudioFiles/thinking_sounds") {
                found = true
            }
            // 2) Try bundle root
            else if let _ = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
                found = true
            }
            // 3) Try path method
            else if let _ = Bundle.main.path(forResource: soundName, ofType: "mp3") {
                found = true
            }
            
            if found {
                foundCount += 1
            } else {
                missingCount += 1
                print("⚠️ Missing bundled thinking sound: \(soundName).mp3")
            }
        }
        
        print("🧠 Bundled thinking sounds loaded: \(foundCount) found, \(missingCount) missing")
        
        if foundCount == 0 {
            print("❌ No bundled thinking sounds found! Check AudioFiles/thinking_sounds directory")
        } else {
            print("✅ Ready to play \(foundCount) high-quality thinking sounds instantly!")
        }
    }
    
    
    // Reset conversation history for new crisis session
    private func resetConversationHistory() {conversationHistory.removeAll()
        lastSentSpeechIndex = 0
        conversationContext = ""
        
        // Reset speech segmentation
        currentSpeechBuffer = ""
        lastSpeechUpdateTime = nil
        speechSegmentTimer?.invalidate()
        speechSegmentTimer = nil
        lastSentSpeech = ""
        
        // Reset thinking sounds
        stopThinkingTimer()
        
        print("🔄 Conversation history reset for new crisis session")
    }
    
    private func sendImageToAI(imageBase64: String) {
        let url = URL(string: "http://\(serverIP):\(serverPort)/upload_image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0 // 10 second timeout for image uploads
        
        let payload = [
            "image": imageBase64,
            "heart_rate": Float(currentHeartRate),  // Convert Int to Float
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        // 🔍 DEBUG: Show image request details
        print("📸 IMAGE STREAM REQUEST:")
        print("📍 URL: \(url)")
        print("📸 Image Size: \(imageBase64.count) characters (Base64)")
        print("📊 Heart Rate: \(currentHeartRate) BPM")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            print("✅ Image request body created")
        } catch {
            print("❌ Failed to create image request: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Image request failed: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("❌ No image response data")
                    return
                }
                
                print("✅ Image response received: \(data.count) bytes")
                self?.processImageResponse(data)
            }
        }.resume()
    }
    
    // MARK: - Thinking Sound Management
    
    private func startThinkingSound() {
        // DISABLED: Thinking sounds are turned off
        print("🎵 Thinking sounds disabled - skipping")
            return
    }
    
    private func stopThinkingSound() {
        if isPlayingThinkingSound {
            thinkingSoundPlayer?.stop()
            thinkingSoundPlayer = nil
            isPlayingThinkingSound = false
            print("🎵 Thinking sound stopped")
        }
    }
    
    // MARK: - Advanced Response Processing
    
    private func processAdvancedResponse(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📝 Advanced response JSON: \(json)")
                
                // Check for end session flag first
                if let endSession = json["end_session"] as? Bool, endSession {
                    print("🏁 Backend indicates session should end")
                    shouldEndSession = true
                    
                    // Play the final response
                    if let audioBase64 = json["audio_base64"] as? String {
                        print("🎵 Playing final session audio")
                        playBase64Audio(audioBase64)
                    } else if let responseText = json["message"] as? String {
                        print("📝 Speaking final session text")
                        speakWithOpenAI(text: responseText, interruptible: false)
                    }
                    
                    // Store the final response
                    if let responseText = json["message"] as? String {
                        lastAIResponse = responseText
                        conversationHistory.append("AI: \(responseText)")
                    }
                    
                    // Play goodbye audio and end the session after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.playGoodbyeAudio()
                    }
                    return
                }
                
                // Look for Base64 audio first, then fallback to text
                if let audioBase64 = json["audio_base64"] as? String {
                    print("🎵 Received Base64 audio response")
                    playBase64Audio(audioBase64)
                    
                    // Also store the text version if available
                    if let responseText = json["response_text"] as? String ?? json["message"] as? String {
                        lastAIResponse = responseText
                        conversationHistory.append("AI: \(responseText)")
                    }
                } else {
                    // Fallback to text response
                    print("📝 No audio found, processing as text response")
                    processSimpleTextResponse(data)
                }
            }
        } catch {
            print("❌ Failed to parse advanced response: \(error)")
            print("📝 Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            speakFallbackInstructions()
        }
    }
    
    // MARK: - Base64 Audio Playback
    
    private func playBase64Audio(_ base64String: String) {
        // Check if Base64 string is empty or invalid
        guard !base64String.isEmpty else {
            print("⚠️ Empty Base64 audio - falling back to text response")
            speakFallbackInstructions()
            return
        }
        
        guard let audioData = Data(base64Encoded: base64String) else {
            print("❌ Failed to decode Base64 audio - invalid format")
            speakFallbackInstructions()
            return
        }
        
        // Check if decoded data is valid (minimum size check)
        guard audioData.count > 100 else {
            print("❌ Base64 audio too small (\(audioData.count) bytes) - likely invalid")
            speakFallbackInstructions()
            return
        }
        
        do {
            // Stop any current audio
            mainAudioPlayer?.stop()
            
            // ENHANCED: Configure audio session for uninterrupted playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try audioSession.setActive(true, options: [])
            print("🔊 Audio session configured for uninterrupted TTS playback")
            
            // Create new audio player with decoded data
            mainAudioPlayer = try AVAudioPlayer(data: audioData)
            mainAudioPlayer?.delegate = self
            
            // ENHANCED: Optimize for speech playback
            mainAudioPlayer?.volume = 1.0
            mainAudioPlayer?.numberOfLoops = 0  // Ensure it plays exactly once
            mainAudioPlayer?.prepareToPlay()
            
            // Validate the audio player is ready
            guard let player = mainAudioPlayer, player.duration > 0 else {
                print("❌ Base64 audio invalid - duration: \(mainAudioPlayer?.duration ?? 0)")
                speakFallbackInstructions()
                return
            }
            
            // ENHANCED: Stop speech recognition during TTS to prevent interruption
            cameraController?.stopSpeechRecognition()
            
            // Play the high-quality audio
            if player.play() {
                isTTSPlaying = true
                print("🎵 Playing Base64 audio (\(audioData.count) bytes, duration: \(player.duration)s) - Speech recognition paused")
            } else {
                print("❌ Failed to start Base64 audio playback")
                cameraController?.resumeSpeechRecognition()
                speakFallbackInstructions()
            }
            
        } catch let error as NSError {
            print("❌ Failed to setup Base64 audio player: \(error.localizedDescription) (Code: \(error.code))")
            if error.code == -39 {
                print("❌ Audio format not supported - check backend TTS format")
            }
            speakFallbackInstructions()
        }
    }
    
    // Simplified response processor that handles existing backend format
    private func processSimpleTextResponse(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📝 Simplified response JSON: \(json)")
                
                // Look for the existing backend's response format first, then fallbacks
                let responseText = json["response_text"] as? String ?? 
                                  json["response"] as? String ?? 
                                  json["message"] as? String ?? 
                                  json["reply"] as? String
                
                if let responseText = responseText, !responseText.isEmpty {
                    print("✅ AI Response: '\(responseText)'")
                    lastAIResponse = responseText
                    
                    // Add AI response to conversation history
                    conversationHistory.append("AI: \(responseText)")
                    
                    speakWithGroundedVoice(responseText)
                    
                    // Process LLM ping request for AR objects
                    processLLMPingRequest(responseText)
                    
                    // Check if AI suggests crisis is over
                    if responseText.lowercased().contains("feeling better") || 
                       responseText.lowercased().contains("crisis over") ||
                       responseText.lowercased().contains("you're safe now") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.endCrisisMode()
                        }
                    }
                } else {
                    print("❌ No response text found in simplified response")
                    speakFallbackInstructions()
                }
            }
        } catch {
            print("❌ Failed to parse simplified response: \(error)")
            print("📝 Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            speakFallbackInstructions()
        }
    }
    
    // Legacy response processor with throttling
    private func processTextResponse(_ data: Data) {
        // Prevent multiple rapid responses - reduced from 3.0s to 1.5s
        let now = Date()
        if let lastResponse = lastResponseTime,
           now.timeIntervalSince(lastResponse) < 1.5 {
            print("🚫 Response throttled - too frequent (last response was \(now.timeIntervalSince(lastResponse))s ago)")
            return
        }
        
        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📝 Raw response: '\(responseString)'")
            print("📊 Response size: \(data.count) bytes")
        }
        
        // Handle null response from server
        if data.count == 4, let responseString = String(data: data, encoding: .utf8), responseString == "null" {
            print("❌ Server returned null - this means your FastAPI server isn't responding properly!")
            print("🔧 Check your FastAPI server - it should return JSON with 'response_text'")
            let fallbackText = "I'm here to help you. Take a deep breath and look around you. Find 5 things you can see."
            lastResponseTime = Date()
            lastAIResponse = fallbackText
            speakWithGroundedVoice(fallbackText)
            return
        }
        
        // Handle empty response
        if data.isEmpty {
            print("❌ Server returned empty response!")
            let fallbackText = "I'm here to help you. Take a deep breath and look around you."
            speakWithGroundedVoice(fallbackText)
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📝 Parsed JSON: \(json)")
                
                let responseText = json["response_text"] as? String ?? 
                                  json["response"] as? String ?? 
                                  json["message"] as? String
                
                        if let responseText = responseText {
                            print("✅ Found response text: '\(responseText)'")
                            
                            // Check if response is relevant to user's input
                            if isResponseRelevant(responseText) {
                                print("✅ Response is relevant to user input")
                                lastResponseTime = Date()
                                lastAIResponse = responseText
                                
                                // Stop thinking timer immediately when response arrives
                                stopThinkingTimer()
                                
                                speakWithGroundedVoice(responseText)
                                
                                // Process LLM ping request for AR objects
                                processLLMPingRequest(responseText)
                            } else {
                                print("🚫 Response not relevant to user input - skipping")
                                stopThinkingTimer()
                            }
                    
                    // Check if AI suggests crisis is over
                    if responseText.lowercased().contains("feeling better") || 
                       responseText.lowercased().contains("crisis over") ||
                       responseText.lowercased().contains("you're safe now") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            self.endCrisisMode()
                        }
                    }
                } else {
                    print("❌ No response text found in JSON")
                    // Provide fallback response
                    let fallbackText = "I'm here to help you. Take a deep breath and look around you."
                    speakWithGroundedVoice(fallbackText)
                }
            }
        } catch {
            print("❌ Failed to parse text response: \(error)")
            print("📝 Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            // Provide fallback response
            let fallbackText = "I'm here to help you. Take a deep breath and look around you."
            speakWithGroundedVoice(fallbackText)
        }
    }
    
    private func processImageResponse(_ data: Data) {
        // Handle null response from server
        if data.count == 4, let responseString = String(data: data, encoding: .utf8), responseString == "null" {
            print("📸 Image processed by AI - visual context updated (null response)")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Image response might contain visual context updates
                print("📸 Image processed by AI - visual context updated")
                
                // If AI wants to provide visual-specific instructions
                if let visualInstruction = json["visual_instruction"] as? String {
                    speakWithGroundedVoice(visualInstruction)
                }
            }
        } catch {
            print("❌ Failed to parse image response: \(error)")
        }
    }
    
    // MARK: - Text-to-Speech
    
    private func speakGroundingInstructions(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact")
        // Voice test removed - using OpenAI TTS only
        
        // Don't auto-end crisis mode - let it continue monitoring
    }
    
    private func setupSpeechSynthesizer() {
        // OpenAI TTS only - no native speech synthesizer setup needed
        
        // Set up audio session for TTS
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("✅ Audio session configured for TTS")
        } catch {
            print("❌ Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - Error Handling
    
    private func handleNetworkError(_ error: Error) {
        print("Network error: \(error.localizedDescription)")
        speakFallbackInstructions()
    }
    
    func handleError(_ message: String) {
        print("Error: \(message)")
        speakFallbackInstructions()
    }
    
    func processSpeechText(_ text: String) {
        print("Processing speech: \(text)")
        print("Speech processing - isListeningEnabled: \(isListeningEnabled), isTTSPlaying: \(isTTSPlaying)")
        
        // Check if listening is enabled - ignore speech during Anchor message
        guard isListeningEnabled else {
            print("Listening disabled - ignoring speech during Anchor message: '\(text)'")
            return
        }
        
        // Phase 2: Intelligent Interruption Logic - Only stop TTS for meaningful speech
        if currentDialoguePhase == .continuousDialogue && isTTSPlaying && text.count > 8 {
            // Only interrupt for substantial speech (more than 8 characters)
            print("🎤 User speaking meaningfully - interrupting TTS")
            stopTTSImmediately()
        }
        
        // Check for urgent verbal cues first (be more specific to avoid false positives)
        let lowercasedText = text.lowercased()
        if lowercasedText.contains("i'm better") || 
           lowercasedText.contains("i feel better") ||
           lowercasedText.contains("i'm okay") ||
           lowercasedText.contains("i feel safe") ||
           lowercasedText.contains("stop the app") ||
           lowercasedText.contains("end session") ||
           lowercasedText.contains("i'm done") {
            print("🚨 Urgent verbal cue detected - ending crisis")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.endCrisisMode()
            }
            return
        }
        
        // Simplified speech processing - just send it if it's long enough
        processSimpleSpeech(text)
    }
    
    // Smart speech processor to prevent API waste
    private func processSimpleSpeech(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Simple length check - 3 to 200 words
        let wordCount = trimmedText.components(separatedBy: .whitespacesAndNewlines).count
        guard wordCount >= 3 && wordCount <= 200 else {
            print("🚫 Speech wrong length: '\(String(trimmedText.prefix(50)))...' (\(wordCount) words - need 3-200)")
            return
        }
        
        // No echo detection needed - manual interrupt button handles this
        
        // Relaxed similarity check for crisis situations (must be <80% similar)
        if !lastSentSpeech.isEmpty {
            let similarity = calculateSimilarity(lastSentSpeech, trimmedText)
            if similarity > 0.8 { // 80% similar - more lenient for crisis situations
                print("🚫 Speech too similar (\(Int(similarity * 100))%): blocking to save API")
                return
            }
        }
        
        // This check is now handled at the camera level - speech is blocked when AI talks
        
        // Extract first meaningful sentence to send
        let meaningfulSentence = extractFirstMeaningfulSentence(trimmedText)
        lastSentSpeech = meaningfulSentence
        print("✅ Sending user speech: '\(meaningfulSentence)'")
        
        // Build conversation context and send
        sendSpeechWithContext(meaningfulSentence)
    }
    
    // Echo detection removed - using manual interrupt button instead
    
    // Extract the first meaningful sentence (not the whole rambling speech)
    private func extractFirstMeaningfulSentence(_ text: String) -> String {
        // Split by common sentence boundaries
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Return first sentence if it's meaningful
        if let firstSentence = sentences.first, firstSentence.components(separatedBy: .whitespacesAndNewlines).count >= 5 {
            return firstSentence
        }
        
        // Otherwise, take first 50 words max
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let firstFiftyWords = Array(words.prefix(50)).joined(separator: " ")
        return firstFiftyWords
    }
    
    // Calculate text similarity (simple word overlap)
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Float {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count
        return union > 0 ? Float(intersection) / Float(union) : 0.0
    }
    
    // Send speech with conversation context
    private func sendSpeechWithContext(_ speech: String) {
        // Add to conversation history
        conversationHistory.append("User: \(speech)")
        
        // Add "Anchor" prefix for first user input after intro
        var processedSpeech = speech
        if isFirstUserInputAfterIntro {
            processedSpeech = "Anchor \(speech)"
            isFirstUserInputAfterIntro = false
            print("🎯 Added 'Anchor' prefix to first user input: '\(processedSpeech)'")
        }
        
        // Send processed text to AI
        print("💬 Sending processed user text: \(processedSpeech)")
        sendSimpleTextToAI(processedSpeech)
    }
    
    // Detect new speech segments by comparing with last sent speech
    private func detectNewSpeechSegments(_ fullText: String) {
        // Skip if speech is too short
        if fullText.count < minSpeechLength {
            print("🚫 Speech segment too short: '\(fullText)' (\(fullText.count) chars)")
            return
        }
        
        // Check for sentence boundaries (periods, question marks, exclamation points)
        let sentenceEnders = [".", "!", "?", ":", ";"]
        let hasSentenceEnd = sentenceEnders.contains { fullText.contains($0) }
        
        // Only process if we have a complete sentence or it's been a while since last speech
        let timeSinceLastSpeech = lastSpeechTime.map { Date().timeIntervalSince($0) } ?? 999.0
        if !hasSentenceEnd && timeSinceLastSpeech < 2.0 {
            print("🚫 Speech segment incomplete: '\(fullText)' (no sentence end)")
            return
        }
        
        // Skip if speech contains AI response patterns (likely AI voice being picked up)
        // But be more specific to avoid blocking user speech
        let aiPatterns = ["I'm here to help you", "focus on the sensation of your feet", "grounding yourself to the present", "exhale slowly through your mouth", "inhale through your nose"]
        for pattern in aiPatterns {
            if fullText.lowercased().contains(pattern.lowercased()) {
                print("🚫 Skipping speech segment - contains AI response pattern: '\(pattern)'")
                return
            }
        }
        
        // Don't block if user is explicitly rejecting AI advice
        if fullText.lowercased().contains("don't tell me") || 
           fullText.lowercased().contains("stop telling me") ||
           fullText.lowercased().contains("no more") {
            print("✅ User rejecting AI advice - allowing speech: '\(fullText)'")
            // Continue processing this speech
        }
        
        // Update last speech time
        lastSpeechTime = Date()
        
        // Log what speech is being processed
        print("🎤 Processing speech segment: '\(fullText)'")
        
        // Log what speech is being processed
        print("🎤 Processing speech segment: '\(fullText)'")
        
        // If this is the first speech or completely different, send it
        if lastSentSpeech.isEmpty || !fullText.hasPrefix(lastSentSpeech) {
            sendNewSpeechSegment(fullText)
            return
        }
        
        // Extract only the new part
        let newPart = String(fullText.dropFirst(lastSentSpeech.count))
        
        // Only send if there's meaningful new content
        if newPart.count >= minSpeechLength {
            // Check if the new part contains sentence boundaries
            let sentences = extractSentences(newPart)
            
            for sentence in sentences {
                if sentence.count >= minSpeechLength {
                    sendNewSpeechSegment(sentence)
                }
            }
        }
    }
    
    // Extract complete sentences from text
    private func extractSentences(_ text: String) -> [String] {
        // Split on sentence boundaries
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return sentences
    }
    
    // Send a new speech segment
    private func sendNewSpeechSegment(_ speech: String) {
        let trimmedSpeech = speech.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only send if it's long enough and not empty
        guard trimmedSpeech.count >= minSpeechLength else {
            print("🚫 Speech segment too short: '\(trimmedSpeech)' (\(trimmedSpeech.count) chars)")
            return
        }
        
        // No throttling here - handled at higher level
        
        // Add to conversation history
        conversationHistory.append(trimmedSpeech)
        print("💬 Added to conversation history: '\(trimmedSpeech)' (Total: \(conversationHistory.count))")
        
        // Send only new speech to AI processing (conversational turn)
        if conversationActive && currentDialoguePhase == .continuousDialogue {
            print("🤖 Sending speech to AI: '\(trimmedSpeech)' (conversationActive: \(conversationActive), phase: \(currentDialoguePhase))")
            // Add a small delay to prevent rapid-fire requests
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sendNewSpeechToAI(trimmedSpeech)
            }
        } else {
            print("🚫 Not sending speech to AI - conversationActive: \(conversationActive), phase: \(currentDialoguePhase)")
        }
        
        // Update last sent speech
        lastSentSpeech = trimmedSpeech
    }
    
    // Send the current speech segment
    private func sendSpeechSegment() {
        let speechToSend = currentSpeechBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only send if it's long enough and not empty
        guard speechToSend.count >= minSpeechLength else {
            print("🚫 Speech segment too short: '\(speechToSend)' (\(speechToSend.count) chars)")
            return
        }
        
        // No throttling - let natural speech flow
        
        // Add to conversation history
        conversationHistory.append(speechToSend)
        print("💬 Added to conversation history: '\(speechToSend)' (Total: \(conversationHistory.count))")
        
        // Send only new speech to AI processing (conversational turn)
        if conversationActive && currentDialoguePhase == .continuousDialogue {
            sendNewSpeechToAI(speechToSend)
        }
        
        // Clear the buffer
        currentSpeechBuffer = ""
        lastSpeechUpdateTime = nil
    }
    
    private func speakFallbackInstructions() {
        // Use OpenAI TTS for fallback
        let fallbackText = "I'm here to help you. Take a deep breath and focus on your surroundings."
        speakWithOpenAI(text: fallbackText, interruptible: true)
    }
    
    // MARK: - Heart Rate Simulation
    
    private func simulateHeartRateMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.isCrisisMode {
                // Simulate elevated heart rate during crisis
                self.currentHeartRate = Int.random(in: 120...150)
            } else {
                // Simulate normal heart rate
                self.currentHeartRate = Int.random(in: 70...85)
            }
        }
    }
    
    func endCrisisMode() {
        print("🛑 Ending crisis mode and resetting phase system")
        
        currentDialoguePhase = .crisisEnd
        isCrisisMode = false
        showCamera = false
        conversationActive = false
        
        // Stop phase transition timer
        phaseTransitionTimer?.invalidate()
        phaseTransitionTimer = nil
        
        // Stop all AR systems
        pingARManager.stopContinuousDetection()
        realTimeARManager.stopRealTimeDetection()
        
        // Reset phase state
        currentPhase = .computerVision
        phaseStartTime = nil
        cvScanCount = 0
        
        // Stop all timers
        crisisTimer?.invalidate()
        crisisTimer = nil
        textStreamTimer?.invalidate()
        textStreamTimer = nil
        imageStreamTimer?.invalidate()
        imageStreamTimer = nil
        // voiceInputTimer removed - using Anchor message duration instead
        print("🛑 All conversation timers stopped")
        thinkingTimer?.invalidate()
        thinkingTimer = nil
        speechSegmentTimer?.invalidate()
        speechSegmentTimer = nil
        
        // Reset all TTS and audio state
        stopAllTTS()
        isProcessingTTS = false
        currentTTSRequest = nil
        pendingTTSRequest = nil
        isTTSPlaying = false
        isAnyAudioPlaying = false
        isProcessingRequest = false
        
        // Reset speech recognition state
        lastSpeechTime = nil
        lastSpeechUpdateTime = nil
        lastSentSpeech = ""
        currentSpeechBuffer = ""
        
        // Reset conversation state
        conversationHistory.removeAll()
        lastResponseTime = nil
        lastTTSRequestTime = nil
        
        // Clear AR overlay state
        arOverlayState.clearOverlay()
        
        // Stop real-time AR detection
        realTimeARManager.stopRealTimeDetection()
        
        // Stop continuous COCO detection
        pingARManager.stopContinuousDetection()
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("🔊 Audio session deactivated")
        } catch {
            print("❌ Failed to deactivate audio session: \(error)")
        }
        
        print("🛑 All streams stopped - crisis intervention complete")
        print("🔄 All state reset for next session")
        print("✅ Phase system reset to initial state")
        
        // Speak ending message with OpenAI TTS
        let endingText = "You're doing great. The crisis intervention is complete. Take care of yourself."
        speakWithOpenAI(text: endingText, interruptible: false)
    }
    
}

// MARK: - AVAudioPlayerDelegate

extension CrisisManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Identify which player finished
        if player == mainAudioPlayer {
            isTTSPlaying = false
            isAnyAudioPlaying = false
            print("Base64 audio finished playing successfully: \(flag)")
            print("Flags reset - isTTSPlaying: \(isTTSPlaying), isListeningEnabled: \(isListeningEnabled)")
            
            // Check if this was goodbye audio (session ending)
            if shouldEndSession {
                print("👋 Goodbye audio finished - ending crisis mode")
                endCrisisMode()
                return
            }
            
            // CRITICAL: Ensure speech recognition is restarted after audio completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.cameraController?.restartSpeechRecognition()
                print("🔊 Speech recognition restarted after Base64 audio completion")
                print("Final flags - isTTSPlaying: \(self.isTTSPlaying), isListeningEnabled: \(self.isListeningEnabled)")
                
                // Process any queued speech after AI finishes
                self.processQueuedSpeech()
            }
        } else if player == thinkingSoundPlayer {
            print("🧠 Thinking sound finished playing successfully: \(flag)")
            isPlayingThinkingSound = false
            
            // Resume speech recognition after thinking sound finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.resumeSpeechRecognition()
                print("▶️ Speech recognition resumed after thinking sound completion")
            }
        } else if player == criticalAudioPlayer {
            isTTSPlaying = false
            isAnyAudioPlaying = false
            criticalAudioPlayer = nil
            print("🎤 Critical audio finished playing successfully: \(flag)")
            
            // Resume speech recognition after critical audio finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.cameraController?.resumeSpeechRecognition()
                print("▶️ Speech recognition resumed after critical audio completion")
                
                // Process any queued speech after critical audio finishes
                self.processQueuedSpeech()
            }
        } else {
            // Legacy OpenAI audio player
            isTTSPlaying = false
            isAnyAudioPlaying = false
            print("🎤 Legacy OpenAI audio finished playing")
            
            // Resume speech recognition for legacy audio too
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.resumeSpeechRecognition()
                print("▶️ Speech recognition resumed after legacy audio completion")
                
                // Process any queued speech after AI finishes
                self.processQueuedSpeech()
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if player == mainAudioPlayer {
        isTTSPlaying = false
            print("❌ Base64 audio decode error: \(error?.localizedDescription ?? "Unknown error")")
            speakFallbackInstructions()
        } else if player == thinkingSoundPlayer {
            isPlayingThinkingSound = false
            print("❌ Thinking sound decode error: \(error?.localizedDescription ?? "Unknown error")")
        } else {
            isTTSPlaying = false
            print("❌ Legacy audio decode error: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    // MARK: - Real AR Data Methods
    
    // Real AR detection will be handled by realTimeARManager and pingARManager
    // No mock data needed - using actual camera feed and backend detection
    
    func processARResponse(_ response: ARResponse) {
        // Processing AR response
        
        // Update AR objects if provided
        if let arData = response.ar_data {
            arOverlayState.updateARObjects(arData)
        }
        
        // Show instruction if provided
        if let instruction = response.responseText {
            arOverlayState.showInstruction(instruction)
        }
        
        // Process audio if provided
        if let audioBase64 = response.audioBase64 {
            playBase64Audio(audioBase64)
        }
    }
    
    // MARK: - LLM-Triggered Ping System
    
    func processLLMPingRequest(_ responseText: String) {
        print("🔔 Processing LLM ping request: \(responseText)")
        
        // Extract object names from LLM response
        let objectNames = extractObjectNamesFromResponse(responseText)
        
        if !objectNames.isEmpty {
            // For now, always use 2D ping overlay
            // TODO: Integrate 3D AR rings when ARKit breathing anchor is active
            pingARManager.triggerPingForObjects(objectNames)
            print("📍 Using 2D ping overlay (3D integration coming soon)")
        }
    }
    
    private func extractObjectNamesFromResponse(_ text: String) -> [String] {
        let lowercasedText = text.lowercased()
        var objectNames: [String] = []
        
        // Common grounding objects that might be mentioned
        let groundingObjects = [
            "table", "chair", "lamp", "window", "door", "plant", "book", "clock",
            "tv", "phone", "cup", "bottle", "picture", "mirror", "bed", "couch",
            "desk", "computer", "keyboard", "mouse", "pen", "paper", "bag",
            "shoes", "clothes", "wall", "floor", "ceiling", "light", "switch"
        ]
        
        for object in groundingObjects {
            if lowercasedText.contains(object) {
                objectNames.append(object)
            }
        }
        
        // Extracted object names for ping
        return objectNames
    }
    
    // MARK: - Testing Functions
    
    func testPingSystem() {
        print("🧪 Testing ping system with real detection")
        print("✨ Ping system will use real objects detected by camera")
        print("📍 Speak object names to trigger pings based on actual detections")
    }
    
    // MARK: - RealityKit Breathing Anchor Test
    
    func testBreathingRing() {
        // Test ARKit breathing anchor with 4-7-8 pattern
        print("Starting ARKit breathing anchor test")
        print("Current showingBreathingAnchor: \(showingBreathingAnchor)")
        print("Current isInARMode: \(isInARMode())")
        
        showingBreathingAnchor = true
        print("Set showingBreathingAnchor to: \(showingBreathingAnchor)")
        
        // Also switch to AR mode to ensure full AR functionality
        if !isInARMode() {
            print("Switching to AR mode for ocean breathing test")
            transitionToARMode()
        }
        
        print("Final showingBreathingAnchor: \(showingBreathingAnchor)")
        print("Final isInARMode: \(isInARMode())")
        print("3D AR ping rings will be available when breathing anchor is active")
    }
    
    // MARK: - Sequential Two-Phase System Implementation
    
    private func startPhase1ComputerVision() {
        print("\(currentPhase.description) - Starting rapid CV scanning")
        currentPhase = .computerVision
        phaseStartTime = Date()
        cvScanCount = 0
        
        // Start rapid CV scanning (1-second intervals)
        pingARManager.startContinuousDetectionWithPhase(.computerVision)
        
        // Schedule automatic transition to AR mode after 10 seconds
        phaseTransitionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.transitionToARMode()
        }
        
        print("Phase 1 timer set for 10 seconds - will automatically transition to AR mode")
    }
    
    func transitionToARMode() {
        print("Transitioning to \(CrisisPhase.arMode.description)")
        
        // STOP ALL DETECTION SYSTEMS - NO MORE PHOTOS OR BACKEND CALLS!
        pingARManager.stopContinuousDetection()
        realTimeARManager.stopRealTimeDetection()
        
        // CRITICAL: Set phase to AR mode in both managers to prevent any detection
        pingARManager.currentPhase = .arMode
        realTimeARManager.currentPhase = .arMode
        print("🛑 ALL detection systems stopped and phase set to AR mode")
        
        // STOP ALL TIMERS - NO MORE PERIODIC TASKS!
        crisisTimer?.invalidate()
        crisisTimer = nil
        textStreamTimer?.invalidate()
        textStreamTimer = nil
        imageStreamTimer?.invalidate()
        imageStreamTimer = nil
        print("🛑 ALL timers stopped")
        
        // STOP CAMERA SESSION
        cameraController?.stopCameraPreview()
        print("📸 Camera session stopped to prevent ARKit conflicts")
        
        // Reset frame counts
        pingARManager.resetFrameCounts()
        realTimeARManager.resetStats()
        print("Frame counts reset")
        
        // Start AR systems
        currentPhase = .arMode
        phaseStartTime = Date()
        
        // DON'T START ANY DETECTION - JUST AR VISUALIZATION
        // pingARManager.startContinuousDetectionWithPhase(.arMode)
        // realTimeARManager.startRealTimeDetectionWithPhase(.arMode)
        
        // Enable AR overlays and 3D ping rings
        showingBreathingAnchor = true
        print("AR overlays and 3D ping rings now enabled")
        print("showingBreathingAnchor set to: \(showingBreathingAnchor)")
        
        print("\(currentPhase.description) - PURE AR VISUALIZATION - NO DETECTION!")
    }
    
    
    // MARK: - Phase Status Monitoring
    
    func getPhaseStatus() -> (phase: CrisisPhase, elapsedTime: TimeInterval, scanCount: Int) {
        let elapsedTime = phaseStartTime?.timeIntervalSinceNow ?? 0
        return (currentPhase, abs(elapsedTime), cvScanCount)
    }
    
    func isInComputerVisionPhase() -> Bool {
        return currentPhase == .computerVision
    }
    
    func isInARMode() -> Bool {
        return currentPhase == .arMode
    }
    
    func incrementScanCount() {
        cvScanCount += 1
        print("📸 CV Scan #\(cvScanCount) completed")
    }
    
    // MARK: - Phase System Testing
    
    func testPhaseTransitions() {
        print("🧪 Testing sequential two-phase system")
        
        // Test Phase 1: CV Scanning
        print("📸 Testing Phase 1: CV Scanning")
        startPhase1ComputerVision()
        
        // Simulate some scans
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.incrementScanCount()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.incrementScanCount()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            self.incrementScanCount()
        }
        
        // Test Phase 2: AR Mode (will happen automatically after 10 seconds)
        print("⏰ Phase 2 transition will occur automatically after 10 seconds")
    }
    
}
