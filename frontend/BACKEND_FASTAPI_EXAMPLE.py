"""
FastAPI Backend Implementation for Grounded App Ping AR System
Complete working example with COCO object detection
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import base64
import cv2
import numpy as np
import time
import logging
from typing import List, Optional
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="Grounded AR Detection API", version="1.0.0")

# Add CORS middleware for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your iOS app's IP
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# COCO Classes mapping
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

# Pydantic models for request/response
class DetectionRequest(BaseModel):
    image: str  # Base64 encoded image
    timestamp: float
    frame_id: int
    detection_type: str

class Detection(BaseModel):
    class_id: int
    box_x: float  # Normalized x coordinate (0.0-1.0)
    box_y: float  # Normalized y coordinate (0.0-1.0)
    confidence: float

class DetectionResponse(BaseModel):
    detections: Optional[List[Detection]]
    processing_time: float
    frame_id: int
    status: str

# Global variables for model (initialize once)
net = None
classes = None

def initialize_model():
    """Initialize the COCO detection model"""
    global net, classes
    
    try:
        # Option 1: Using OpenCV DNN with YOLO
        # Download YOLOv4 weights and config from: https://github.com/AlexeyAB/darknet
        # net = cv2.dnn.readNet("yolov4.weights", "yolov4.cfg")
        
        # Option 2: Using a lighter model like MobileNet SSD
        # net = cv2.dnn.readNet("MobileNetSSD_deploy.caffemodel", "MobileNetSSD_deploy.prototxt")
        
        # For this example, we'll simulate the model
        logger.info("Model initialized (simulation mode)")
        classes = list(COCO_CLASSES.values())
        
    except Exception as e:
        logger.error(f"Failed to initialize model: {e}")
        raise

def detect_objects_opencv(image):
    """
    Detect objects using OpenCV DNN
    Replace this with your actual model inference
    """
    global net, classes
    
    if net is None:
        # Simulate detections for testing
        return simulate_detections(image)
    
    try:
        # Get image dimensions
        height, width = image.shape[:2]
        
        # Create blob from image
        blob = cv2.dnn.blobFromImage(image, 1/255.0, (416, 416), swapRB=True, crop=False)
        
        # Set input to the network
        net.setInput(blob)
        
        # Run forward pass
        outputs = net.forward()
        
        # Process outputs
        detections = []
        for output in outputs:
            for detection in output:
                scores = detection[5:]
                class_id = np.argmax(scores)
                confidence = scores[class_id]
                
                if confidence > 0.5:  # Confidence threshold
                    # Get bounding box coordinates
                    center_x = int(detection[0] * width)
                    center_y = int(detection[1] * height)
                    w = int(detection[2] * width)
                    h = int(detection[3] * height)
                    
                    # Convert to normalized coordinates
                    norm_x = center_x / width
                    norm_y = center_y / height
                    
                    detections.append({
                        'class_id': class_id,
                        'box_x': norm_x,
                        'box_y': norm_y,
                        'confidence': float(confidence)
                    })
        
        return detections
        
    except Exception as e:
        logger.error(f"Detection error: {e}")
        return []

def simulate_detections(image):
    """
    Simulate object detections for testing
    Replace this with actual model inference
    """
    height, width = image.shape[:2]
    
    # Simulate some common objects
    simulated_detections = [
        {
            'class_id': 56,  # chair
            'box_x': 0.3,
            'box_y': 0.6,
            'confidence': 0.95
        },
        {
            'class_id': 58,  # potted plant
            'box_x': 0.7,
            'box_y': 0.3,
            'confidence': 0.87
        },
        {
            'class_id': 62,  # tv
            'box_x': 0.2,
            'box_y': 0.2,
            'confidence': 0.92
        },
        {
            'class_id': 39,  # bottle
            'box_x': 0.8,
            'box_y': 0.7,
            'confidence': 0.78
        }
    ]
    
    # Add some randomness to simulate real detection
    import random
    random.shuffle(simulated_detections)
    
    # Return 1-3 random detections
    return simulated_detections[:random.randint(1, 3)]

def decode_base64_image(image_base64: str):
    """Decode base64 image string to OpenCV image"""
    try:
        # Remove data URL prefix if present
        if ',' in image_base64:
            image_base64 = image_base64.split(',')[1]
        
        # Decode base64
        image_data = base64.b64decode(image_base64)
        
        # Convert to numpy array
        nparr = np.frombuffer(image_data, np.uint8)
        
        # Decode image
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise ValueError("Failed to decode image")
        
        return image
        
    except Exception as e:
        logger.error(f"Image decoding error: {e}")
        raise HTTPException(status_code=400, detail=f"Invalid image data: {e}")

@app.on_event("startup")
async def startup_event():
    """Initialize model on startup"""
    logger.info("Starting Grounded AR Detection API...")
    initialize_model()
    logger.info("API ready!")

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "message": "Grounded AR Detection API",
        "status": "running",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "model_loaded": net is not None,
        "coco_classes": len(COCO_CLASSES),
        "timestamp": time.time()
    }

@app.post("/upload_image", response_model=DetectionResponse)
async def process_image(request: DetectionRequest):
    """
    Main endpoint for processing camera frames
    Returns COCO object detections with normalized coordinates
    """
    start_time = time.time()
    
    try:
        logger.info(f"Processing frame {request.frame_id}")
        
        # Decode base64 image
        image = decode_base64_image(request.image)
        
        # Log image info
        height, width = image.shape[:2]
        logger.info(f"Image size: {width}x{height}")
        
        # Run object detection
        detections = detect_objects_opencv(image)
        
        # Convert to response format
        detection_objects = []
        for det in detections:
            detection_objects.append(Detection(
                class_id=det['class_id'],
                box_x=det['box_x'],
                box_y=det['box_y'],
                confidence=det['confidence']
            ))
        
        processing_time = time.time() - start_time
        
        logger.info(f"Detected {len(detection_objects)} objects in {processing_time:.3f}s")
        
        return DetectionResponse(
            detections=detection_objects,
            processing_time=processing_time,
            frame_id=request.frame_id,
            status="success"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        processing_time = time.time() - start_time
        logger.error(f"Processing error: {e}")
        
        return DetectionResponse(
            detections=None,
            processing_time=processing_time,
            frame_id=request.frame_id,
            status=f"error: {str(e)}"
        )

@app.get("/classes")
async def get_coco_classes():
    """Get all COCO class names"""
    return {
        "classes": COCO_CLASSES,
        "total_classes": len(COCO_CLASSES)
    }

@app.get("/stats")
async def get_stats():
    """Get API statistics"""
    return {
        "uptime": time.time(),
        "model_loaded": net is not None,
        "supported_classes": len(COCO_CLASSES),
        "api_version": "1.0.0"
    }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return {
        "error": exc.detail,
        "status_code": exc.status_code,
        "timestamp": time.time()
    }

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {exc}")
    return {
        "error": "Internal server error",
        "status_code": 500,
        "timestamp": time.time()
    }

if __name__ == "__main__":
    # Run the server
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,  # Set to False in production
        log_level="info"
    )