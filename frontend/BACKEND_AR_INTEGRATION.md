# 🎯 Real-Time AR Backend Integration Guide

## Overview
This guide explains how to integrate OpenCV object detection with the iOS app for real-time AR overlays.

## 📡 Backend Endpoint Requirements

### New Endpoint: `/process_frame`
**Purpose**: Process camera frames in real-time for AR object detection

**Request Format**:
```json
{
    "image": "base64_encoded_image_data",
    "timestamp": 1234567890.123,
    "frame_id": 42,
    "request_type": "real_time_ar"
}
```

**Response Format**:
```json
{
    "audioBase64": "optional_base64_audio_data",
    "responseText": "optional_instruction_text",
    "ar_data": [
        {
            "label": "table",
            "box_x": 0.45,
            "box_y": 0.60,
            "color": "brown"
        },
        {
            "label": "red lamp",
            "box_x": 0.50,
            "box_y": 0.30,
            "color": "red"
        }
    ],
    "processing_time": 0.15,
    "frame_id": 42,
    "confidence_scores": [0.95, 0.87]
}
```

## 🔧 OpenCV Integration

### Coordinate System
- **Input**: OpenCV coordinates (0,0 = top-left)
- **Output**: Normalized coordinates (0.0-1.0) for iOS
- **Conversion**: `normalized_x = cv_x / image_width`, `normalized_y = cv_y / image_height`

### Object Detection Pipeline
```python
import cv2
import numpy as np
import base64
from typing import List, Dict, Tuple

class RealTimeARProcessor:
    def __init__(self):
        # Initialize your OpenCV models
        self.detector = cv2.HOGDescriptor()
        # Or use YOLO, SSD, etc.
        
    def process_frame(self, image_data: bytes) -> Dict:
        # Decode image
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # Detect objects
        detections = self.detect_objects(image)
        
        # Convert to normalized coordinates
        ar_objects = self.convert_to_ar_format(detections, image.shape)
        
        return {
            "ar_data": ar_objects,
            "processing_time": 0.15,  # Measure actual time
            "confidence_scores": [d.confidence for d in detections]
        }
    
    def detect_objects(self, image) -> List[Detection]:
        # Your OpenCV detection logic here
        # Return list of Detection objects with:
        # - label: str
        # - bbox: (x, y, w, h) in pixels
        # - confidence: float
        pass
    
    def convert_to_ar_format(self, detections: List[Detection], image_shape: Tuple) -> List[Dict]:
        height, width = image_shape[:2]
        ar_objects = []
        
        for detection in detections:
            x, y, w, h = detection.bbox
            
            # Convert to center point and normalize
            center_x = (x + w/2) / width
            center_y = (y + h/2) / height
            
            ar_objects.append({
                "label": detection.label,
                "box_x": center_x,
                "box_y": center_y,
                "color": self.get_color_for_label(detection.label)
            })
        
        return ar_objects
```

## ⚡ Performance Optimization

### Real-Time Requirements
- **Target**: < 1 second processing time
- **Frame Rate**: 1-2 FPS (not 30 FPS like video)
- **Latency**: < 500ms end-to-end

### Optimization Strategies
1. **Image Resizing**: Resize to 640x480 before processing
2. **Model Optimization**: Use lightweight models (MobileNet, etc.)
3. **Async Processing**: Process frames in background threads
4. **Caching**: Cache model weights and common detections

### Backend Performance Monitoring
```python
import time
from collections import deque

class PerformanceMonitor:
    def __init__(self, window_size=100):
        self.processing_times = deque(maxlen=window_size)
        self.frame_count = 0
        
    def record_processing_time(self, duration: float):
        self.processing_times.append(duration)
        self.frame_count += 1
        
    def get_stats(self):
        if not self.processing_times:
            return {"avg_time": 0, "max_time": 0, "frame_count": 0}
            
        return {
            "avg_time": sum(self.processing_times) / len(self.processing_times),
            "max_time": max(self.processing_times),
            "frame_count": self.frame_count
        }
```

## 🎨 AR Visualization Options

### 1. Simple Dots
- **Best for**: Fast processing, minimal visual clutter
- **Implementation**: Small colored circles at detection points

### 2. Pulsing Circles (Current)
- **Best for**: Clear object emphasis
- **Implementation**: Animated circles with labels

### 3. Bounding Boxes
- **Best for**: Precise object boundaries
- **Implementation**: Rectangles around detected objects

### 4. 3D Objects (Future)
- **Best for**: Immersive AR experience
- **Implementation**: ARKit integration with 3D models

## 🚀 Implementation Steps

### Phase 1: Basic Integration (Week 1)
1. Create `/process_frame` endpoint
2. Implement basic OpenCV object detection
3. Test with iOS app mock data

### Phase 2: Real-Time Optimization (Week 2)
1. Optimize processing speed
2. Implement performance monitoring
3. Add confidence scores

### Phase 3: Enhanced Features (Week 3)
1. Add multiple visualization modes
2. Implement object tracking
3. Add 3D object support

## 📊 Expected Performance

### Processing Times
- **Simple Detection**: 100-200ms
- **Complex Detection**: 300-500ms
- **With Tracking**: 200-400ms

### Accuracy Targets
- **Object Detection**: > 85% accuracy
- **Coordinate Precision**: ±5 pixels
- **Real-Time Latency**: < 1 second

## 🔍 Testing Strategy

### Backend Testing
```python
def test_frame_processing():
    # Load test image
    with open("test_frame.jpg", "rb") as f:
        image_data = f.read()
    
    # Process frame
    result = processor.process_frame(image_data)
    
    # Validate response
    assert "ar_data" in result
    assert len(result["ar_data"]) > 0
    assert result["processing_time"] < 1.0
```

### iOS Integration Testing
1. Test with mock data first
2. Gradually increase frame rate
3. Monitor performance metrics
4. Test with real camera feeds

## 🎯 Success Metrics

- **Latency**: < 1 second end-to-end
- **Accuracy**: > 85% object detection
- **Stability**: No crashes during 10+ minute sessions
- **Performance**: Smooth 60fps UI updates

This system will provide real-time AR object detection with smooth, responsive overlays on the iOS app!