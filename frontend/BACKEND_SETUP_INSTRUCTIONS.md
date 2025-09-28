# 🚀 Backend Setup Instructions for Grounded AR Detection

## Quick Start

### 1. Install Dependencies
```bash
# Create virtual environment
python -m venv grounded_env
source grounded_env/bin/activate  # On Windows: grounded_env\Scripts\activate

# Install requirements
pip install -r requirements.txt
```

### 2. Run the Server
```bash
# Development mode (using the provided example)
python BACKEND_FASTAPI_EXAMPLE.py

# Or using uvicorn directly
uvicorn BACKEND_FASTAPI_EXAMPLE:app --host 0.0.0.0 --port 2419 --reload
```

### 3. Test the API
```bash
# Health check
curl http://localhost:2419/health

# Test COCO object detection (current working endpoint)
curl -X POST "http://localhost:2419/coco_detection" \
     -H "Content-Type: application/json" \
     -d '{
       "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
       "timestamp": 1234567890.123,
       "frame_id": 1
     }'

# Test image upload for visual context
curl -X POST "http://localhost:2419/upload_image" \
     -H "Content-Type: application/json" \
     -d '{
       "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
       "timestamp": 1234567890.123,
       "frame_id": 1,
       "heart_rate": 125
     }'
```

## 🔧 Model Integration Options

### Option 1: YOLO with OpenCV DNN (Recommended)
```python
# Download YOLOv4 weights and config
wget https://github.com/AlexeyAB/darknet/releases/download/yolov4/yolov4.weights
wget https://raw.githubusercontent.com/AlexeyAB/darknet/master/cfg/yolov4.cfg

# Update the initialize_model() function
def initialize_model():
    global net, classes
    net = cv2.dnn.readNet("yolov4.weights", "yolov4.cfg")
    classes = list(COCO_CLASSES.values())
```

### Option 2: MobileNet SSD (Faster)
```python
# Download MobileNet SSD files
wget https://github.com/chuanqi305/MobileNet-SSD/raw/master/MobileNetSSD_deploy.caffemodel
wget https://raw.githubusercontent.com/chuanqi305/MobileNet-SSD/master/MobileNetSSD_deploy.prototxt

# Update the initialize_model() function
def initialize_model():
    global net, classes
    net = cv2.dnn.readNet("MobileNetSSD_deploy.caffemodel", "MobileNetSSD_deploy.prototxt")
    classes = list(COCO_CLASSES.values())
```

### Option 3: YOLOv8 with Ultralytics (Most Accurate)
```python
# Install ultralytics
pip install ultralytics

# Update the detect_objects_opencv function
from ultralytics import YOLO

def initialize_model():
    global model
    model = YOLO('yolov8n.pt')  # or yolov8s.pt, yolov8m.pt, etc.

def detect_objects_yolo(image):
    results = model(image)
    detections = []
    
    for result in results:
        boxes = result.boxes
        for box in boxes:
            # Get coordinates
            x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
            conf = box.conf[0].cpu().numpy()
            cls = int(box.cls[0].cpu().numpy())
            
            # Convert to center point and normalize
            height, width = image.shape[:2]
            center_x = (x1 + x2) / 2 / width
            center_y = (y1 + y2) / 2 / height
            
            detections.append({
                'class_id': cls,
                'box_x': center_x,
                'box_y': center_y,
                'confidence': float(conf)
            })
    
    return detections
```

## 🐳 Docker Deployment

### Dockerfile
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY BACKEND_FASTAPI_EXAMPLE.py .
COPY requirements.txt .

# Download model files (if using YOLO)
# RUN wget https://github.com/AlexeyAB/darknet/releases/download/yolov4/yolov4.weights
# RUN wget https://raw.githubusercontent.com/AlexeyAB/darknet/master/cfg/yolov4.cfg

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "BACKEND_FASTAPI_EXAMPLE:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Commands
```bash
# Build image
docker build -t grounded-ar-backend .

# Run container
docker run -p 8000:8000 grounded-ar-backend

# Run with volume for model files
docker run -p 8000:8000 -v $(pwd)/models:/app/models grounded-ar-backend
```

## 🔧 Configuration

### Environment Variables
```bash
# Create .env file
MODEL_PATH=./models/yolov4.weights
CONFIDENCE_THRESHOLD=0.5
MAX_DETECTIONS=10
LOG_LEVEL=INFO
```

### Update the code to use environment variables:
```python
import os
from dotenv import load_dotenv

load_dotenv()

MODEL_PATH = os.getenv("MODEL_PATH", "./models/yolov4.weights")
CONFIDENCE_THRESHOLD = float(os.getenv("CONFIDENCE_THRESHOLD", "0.5"))
MAX_DETECTIONS = int(os.getenv("MAX_DETECTIONS", "10"))
```

## 📊 Performance Optimization

### 1. Model Optimization
```python
# Use smaller models for faster inference
# YOLOv8n (nano) - fastest
# YOLOv8s (small) - balanced
# YOLOv8m (medium) - more accurate

model = YOLO('yolov8n.pt')  # Fastest option
```

### 2. Image Preprocessing
```python
def preprocess_image(image):
    # Resize to standard size for faster processing
    image = cv2.resize(image, (640, 480))
    
    # Apply any other preprocessing
    return image
```

### 3. Batch Processing
```python
# Process multiple images at once (if needed)
def process_batch(images):
    # Your batch processing logic
    pass
```

## 🧪 Testing

### Unit Tests
```python
# test_api.py
import pytest
from fastapi.testclient import TestClient
from BACKEND_FASTAPI_EXAMPLE import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_image_processing():
    # Test with a simple base64 image
    test_image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
    
    response = client.post("/upload_image", json={
        "image": test_image,
        "timestamp": 1234567890.123,
        "frame_id": 1,
        "detection_type": "coco_continuous"
    })
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "detections" in data
```

### Load Testing
```python
# load_test.py
import requests
import time
import concurrent.futures

def test_endpoint():
    url = "http://localhost:8000/upload_image"
    data = {
        "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
        "timestamp": time.time(),
        "frame_id": 1,
        "detection_type": "coco_continuous"
    }
    
    response = requests.post(url, json=data)
    return response.status_code == 200

# Run 100 concurrent requests
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
    futures = [executor.submit(test_endpoint) for _ in range(100)]
    results = [f.result() for f in futures]

success_rate = sum(results) / len(results)
print(f"Success rate: {success_rate:.2%}")
```

## 🚀 Production Deployment

### Using Gunicorn
```bash
# Install gunicorn
pip install gunicorn

# Run with gunicorn
gunicorn BACKEND_FASTAPI_EXAMPLE:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Using Nginx (Reverse Proxy)
```nginx
# /etc/nginx/sites-available/grounded-ar
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Systemd Service
```ini
# /etc/systemd/system/grounded-ar.service
[Unit]
Description=Grounded AR Detection API
After=network.target

[Service]
Type=exec
User=your-user
WorkingDirectory=/path/to/your/app
Environment=PATH=/path/to/your/app/grounded_env/bin
ExecStart=/path/to/your/app/grounded_env/bin/uvicorn BACKEND_FASTAPI_EXAMPLE:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

## 📱 iOS Integration

### Update iOS app server URL
In your iOS app, update the server IP:
```swift
private let serverIP = "YOUR_SERVER_IP"  // Replace with actual server IP
private let serverPort = "8000"  // Or your chosen port
```

### Test with iOS app
1. Run the backend server
2. Update iOS app with correct server IP
3. Start crisis mode in iOS app
4. Check backend logs for incoming requests
5. Verify ping system works correctly

This setup provides a complete, production-ready backend for your Grounded AR detection system!