# 🧘 Grounded - AI-Powered Crisis Intervention App

A real-time AR object detection and crisis intervention iOS app that helps users during panic attacks through visual grounding, AI conversation, and calming audio.

## ✨ Current Features

### 🎯 **Real-Time AR Object Detection**
- **Live camera feed** with continuous object detection
- **COCO dataset** object recognition (80+ object classes)
- **Backend integration** with OpenCV processing
- **Coordinate normalization** for AR visualization
- **Optimized performance** to prevent UI freezing

### 🎤 **Advanced Audio System**
- **Real-time speech recognition** with continuous monitoring
- **AI conversation** with OpenAI GPT integration
- **Text-to-speech** with native iOS voices
- **Thinking sounds** during AI processing
- **Audio interruption prevention** - AI completes responses
- **Teleprompter-style text scrolling** for long responses

### 📱 **Crisis Intervention Features**
- **Panic attack detection** via heart rate simulation
- **Visual grounding** through AR object highlighting
- **Calming audio** and breathing exercises
- **Professional UI** with gradient backgrounds
- **Haptic feedback** for user interaction

### 🔧 **Technical Architecture**
- **SwiftUI** for modern iOS interface
- **AVFoundation** for camera and audio
- **Core ML** for on-device processing
- **HTTP networking** for backend communication
- **Real-time data streaming** to backend services

## 🚀 Quick Start

### Prerequisites
- iOS 16.0+
- Xcode 15.0+
- Backend server running (see Backend Setup)

### Installation
1. Clone the repository
2. Open `Grounded.xcodeproj` in Xcode
3. Update backend IP in `CrisisManager.swift` (line ~20)
4. Build and run on device or simulator

### Backend Configuration
Update the server IP address in `CrisisManager.swift`:
```swift
private let serverIP = "100.66.12.253" // Your backend IP
private let serverPort = "2419"        // Your backend port
```

## 🏗️ Architecture

### Core Components
- **`CrisisManager`** - Central crisis intervention logic
- **`CameraView`** - Camera capture and AR visualization
- **`PingARSystem`** - Continuous object detection
- **`RealTimeARManager`** - Real-time AR processing
- **`BottomCaptionView`** - Speech-to-text display with teleprompter

### Data Flow
1. **Camera captures** live video feed
2. **AR managers** process frames every 3-5 seconds
3. **Backend receives** base64 images for OpenCV processing
4. **Coordinates returned** for AR visualization
5. **AI conversation** handles user speech and responses

## 🔧 Configuration

### Backend Endpoints
- **`POST /upload_image`** - Image processing for visual context
- **`POST /start-new-anxiety`** - Crisis session initialization
- **`POST /grounding`** - Main crisis intervention endpoint
- **`POST /coco_detection`** - Object detection processing

### Audio Settings
- **Speech recognition** - Continuous monitoring
- **TTS voice** - Samantha (calming, 0.4x rate)
- **Audio format** - AAC 44.1kHz mono
- **Thinking sounds** - Bundled audio files

## 📱 Usage

### Starting a Crisis Session
1. Tap **"I NEED GROUNDED"** button
2. App enters crisis mode with heart rate simulation
3. Camera activates for visual grounding
4. AI begins conversation and object detection

### During Crisis
- **Speak naturally** - AI listens and responds
- **Look at objects** - AR highlights detected items
- **Follow AI guidance** - Calming instructions and grounding
- **Tap "Stop"** - End crisis session anytime

### Ending Session
- Say **"I'm better"** or **"I feel okay"**
- Tap **"Stop Panic Attack"** button
- AI provides closing message and session ends

## 🛠️ Development

### Key Files
- **`CrisisManager.swift`** - Main crisis logic and AI integration
- **`CameraView.swift`** - Camera, speech recognition, and UI
- **`PingARSystem.swift`** - Object detection and AR visualization
- **`ContentView.swift`** - Main app interface

### Debugging
- **Console logs** show detailed operation status
- **Network requests** logged with full details
- **Audio status** tracked throughout session
- **AR detection** shows object coordinates and confidence

## 🔮 Future Enhancements

- **3D AR visualization** with ARKit
- **Advanced breathing exercises** with haptic feedback
- **Personalized crisis responses** based on user history
- **Offline mode** with on-device AI processing
- **Apple Watch integration** for heart rate monitoring

## 📄 License

This project is for educational and therapeutic purposes. Please ensure proper medical supervision for crisis intervention features.

---

**Built with ❤️ for mental health support and crisis intervention**
