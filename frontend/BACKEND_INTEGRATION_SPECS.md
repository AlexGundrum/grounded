# 🎯 Backend Integration Specifications for Grounded AR System

## Overview
This document provides exact specifications for the backend COCO object detection system that integrates with the Grounded iOS app. **Current working backend: 100.66.12.253:2419**

## ✅ Currently Working Endpoints
- **`/coco_detection`** - COCO object detection (primary)
- **`/upload_image`** - Visual context for AI conversation
- **`/start-new-anxiety`** - Crisis session initialization

## 📡 Endpoint Specifications

### Endpoint: `/upload_image`
**Purpose**: Process camera frames for continuous COCO object detection

**Method**: `POST`
**Content-Type**: `application/json`

### Request Format
```json
{
    "image": "base64_encoded_image_data",
    "timestamp": 1234567890.123,
    "frame_id": 42,
    "detection_type": "coco_continuous"
}
```

### Response Format
```json
{
    "detections": [
        {
            "class_id": 56,
            "box_x": 0.3,
            "box_y": 0.6,
            "confidence": 0.95
        },
        {
            "class_id": 58,
            "box_x": 0.7,
            "box_y": 0.3,
            "confidence": 0.87
        }
    ],
    "processing_time": 0.15,
    "frame_id": 42,
    "status": "success"
}
```

## 🔧 Technical Requirements

### Image Processing
- **Input**: Base64 encoded JPEG image
- **Resolution**: 640x480 (recommended for performance)
- **Format**: JPEG with 80% compression quality
- **Processing Time**: < 2 seconds (target: < 1 second)

### Coordinate System
- **Input**: OpenCV coordinates (0,0 = top-left corner)
- **Output**: Normalized coordinates (0.0-1.0 range)
- **Conversion Formula**:
  ```python
  normalized_x = center_x / image_width
  normalized_y = center_y / image_height
  ```

### COCO Classes (80 classes)
```python
COCO_CLASSES = {
    0: 'person', 1: 'bicycle', 2: 'car', 3: 'motorcycle', 4: 'airplane', 5: 'bus',
    6: 'train', 7: 'truck', 8: 'boat', 9: 'traffic light', 10: 'fire hydrant',
    11: 'stop sign', 12: 'parking meter', 13: 'bench', 14: 'bird', 15: 'cat',
    16: 'dog', 17: 'horse', 18: 'sheep', 19: 'cow', 20: 'elephant', 21: 'bear',
    22: 'zebra', 23: 'giraffe', 24: 'backpack', 25: 'umbrella', 26: 'handbag',
    27: 'tie', 28: 'suitcase', 29: 'frisbee', 30: 'skis', 31: 'snowboard',
    32: 'sports ball', 33: 'kite', 34: 'baseball bat', 35: 'baseball glove',
    36: 'skateboard', 37: 'surfboard', 38: 'tennis racket', 39: 'bottle',
    40: 'wine glass', 41: 'cup', 42: 'fork', 43: 'knife', 44: 'spoon', 45: 'bowl',
    46: 'banana', 47: 'apple', 48: 'sandwich', 49: 'orange', 50: 'broccoli',
    51: 'carrot', 52: 'hot dog', 53: 'pizza', 54: 'donut', 55: 'cake', 56: 'chair',
    57: 'couch', 58: 'potted plant', 59: 'bed', 60: 'dining table', 61: 'toilet',
    62: 'tv', 63: 'laptop', 64: 'mouse', 65: 'remote', 66: 'keyboard', 67: 'cell phone',
    68: 'microwave', 69: 'oven', 70: 'toaster', 71: 'sink', 72: 'refrigerator',
    73: 'book', 74: 'clock', 75: 'vase', 76: 'scissors', 77: 'teddy bear',
    78: 'hair drier', 79: 'toothbrush'
}
```

## 🐍 Python Implementation Example

### FastAPI Endpoint
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import base64
import cv2
import numpy as np
import time
from typing import List, Optional

app = FastAPI()

class DetectionRequest(BaseModel):
    image: str
    timestamp: float
    frame_id: int
    detection_type: str

class Detection(BaseModel):
    class_id: int
    box_x: float
    box_y: float
    confidence: float

class DetectionResponse(BaseModel):
    detections: Optional[List[Detection]]
    processing_time: float
    frame_id: int
    status: str

@app.post("/upload_image", response_model=DetectionResponse)
async def process_image(request: DetectionRequest):
    start_time = time.time()
    
    try:
        # Decode base64 image
        image_data = base64.b64decode(request.image)
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Invalid image data")
        
        # Process image with your COCO model
        detections = process_coco_detection(image)
        
        processing_time = time.time() - start_time
        
        return DetectionResponse(
            detections=detections,
            processing_time=processing_time,
            frame_id=request.frame_id,
            status="success"
        )
        
    except Exception as e:
        processing_time = time.time() - start_time
        return DetectionResponse(
            detections=None,
            processing_time=processing_time,
            frame_id=request.frame_id,
            status=f"error: {str(e)}"
        )

def process_coco_detection(image):
    """
    Your COCO detection logic here
    Returns list of Detection objects
    """
    # Example implementation:
    detections = []
    
    # Your model inference here
    # results = model(image)
    
    # Convert results to normalized coordinates
    height, width = image.shape[:2]
    
    # Example detections (replace with your actual model output)
    example_detections = [
        {"class_id": 56, "bbox": [100, 200, 200, 150], "confidence": 0.95},  # chair
        {"class_id": 58, "bbox": [300, 100, 80, 120], "confidence": 0.87},   # plant
    ]
    
    for det in example_detections:
        x, y, w, h = det["bbox"]
        
        # Convert to center point and normalize
        center_x = (x + w/2) / width
        center_y = (y + h/2) / height
        
        detections.append(Detection(
            class_id=det["class_id"],
            box_x=center_x,
            box_y=center_y,
            confidence=det["confidence"]
        ))
    
    return detections
```

### OpenCV Integration
```python
import cv2
import numpy as np

def setup_coco_model():
    """Initialize your COCO detection model"""
    # Example with YOLO
    # net = cv2.dnn.readNet("yolov4.weights", "yolov4.cfg")
    # classes = load_coco_classes()
    pass

def detect_objects(image):
    """Run object detection on image"""
    # Your detection logic here
    # Return list of detections with bbox and confidence
    pass

def normalize_coordinates(bbox, image_shape):
    """Convert bbox to normalized coordinates"""
    height, width = image_shape[:2]
    x, y, w, h = bbox
    
    # Convert to center point
    center_x = (x + w/2) / width
    center_y = (y + h/2) / height
    
    return center_x, center_y
```

## ⚡ Performance Requirements

### Timing
- **Target Processing Time**: < 1 second
- **Maximum Processing Time**: < 2 seconds
- **Update Frequency**: Every 2 seconds from iOS
- **Timeout**: 3 seconds

### Optimization Tips
1. **Image Resizing**: Resize input to 640x480 before processing
2. **Model Optimization**: Use lightweight models (MobileNet, etc.)
3. **Batch Processing**: Process multiple detections efficiently
4. **Caching**: Cache model weights and common operations

### Error Handling
```python
# Handle various error cases
try:
    # Image processing
    pass
except cv2.error as e:
    return {"status": "error", "message": f"OpenCV error: {e}"}
except Exception as e:
    return {"status": "error", "message": f"Processing error: {e}"}
```

## 🧪 Testing

### Test Images
Create test images with known objects:
- Chair at (0.3, 0.6)
- Plant at (0.7, 0.3)
- TV at (0.2, 0.2)
- Bottle at (0.8, 0.7)

### Test Request
```bash
curl -X POST "http://localhost:8000/upload_image" \
     -H "Content-Type: application/json" \
     -d '{
       "image": "base64_encoded_test_image",
       "timestamp": 1234567890.123,
       "frame_id": 1,
       "detection_type": "coco_continuous"
     }'
```

### Expected Response
```json
{
    "detections": [
        {
            "class_id": 56,
            "box_x": 0.3,
            "box_y": 0.6,
            "confidence": 0.95
        }
    ],
    "processing_time": 0.15,
    "frame_id": 1,
    "status": "success"
}
```

## 📊 Monitoring

### Logging
```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.post("/upload_image")
async def process_image(request: DetectionRequest):
    logger.info(f"Processing frame {request.frame_id}")
    
    # ... processing ...
    
    logger.info(f"Detected {len(detections)} objects in {processing_time:.2f}s")
```

### Metrics
- Processing time per frame
- Number of detections per frame
- Error rate
- Memory usage

## 🚀 Deployment

### Requirements
- Python 3.8+
- FastAPI
- OpenCV
- Your COCO model (YOLO, SSD, etc.)

### Docker Example
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

This specification ensures your backend developer has everything needed to implement the COCO detection system that will work seamlessly with the iOS Ping AR system!