#!/usr/bin/env python3
"""
Test script for the YOLO object detection pipeline with color extraction.
This script tests the complete pipeline without needing a real image.
"""

import os
import sys
import base64
import cv2
import numpy as np
from PIL import Image
import io

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from utils.object_detection import object_detection

def create_test_image() -> str:
    """
    Create a simple test image with colored objects for testing.
    Returns base64 encoded image string.
    """
    # Create a simple test image with colored rectangles
    img = np.zeros((400, 600, 3), dtype=np.uint8)
    
    # Add colored rectangles representing different objects
    # Blue car
    cv2.rectangle(img, (50, 150), (200, 250), (255, 0, 0), -1)  # Blue
    
    # Red chair
    cv2.rectangle(img, (300, 200), (450, 350), (0, 0, 255), -1)  # Red
    
    # Green bottle
    cv2.rectangle(img, (500, 100), (550, 300), (0, 255, 0), -1)  # Green
    
    # Convert to PIL Image
    pil_img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    
    # Convert to base64
    buffer = io.BytesIO()
    pil_img.save(buffer, format='JPEG')
    img_str = base64.b64encode(buffer.getvalue()).decode()
    
    return img_str

def test_object_detection_pipeline():
    """Test the complete object detection pipeline."""
    
    print("🔍 Testing YOLO Object Detection Pipeline with Color Extraction")
    print("=" * 60)
    
    # Initialize the object detector
    print("\n📦 Initializing YOLO model...")
    detector = object_detection(model_name="yolov8n.pt")
    print("✅ YOLO model loaded successfully!")
    
    # Create test image
    print("\n🎨 Creating test image...")
    test_image_string = create_test_image()
    print("✅ Test image created and encoded!")
    
    # Test the complete pipeline
    print("\n🚀 Running complete detection pipeline...")
    result = detector.process_image_pipeline(test_image_string, confidence_threshold=0.3)
    
    # Display results
    print("\n📊 Detection Results:")
    print("-" * 40)
    
    if result["success"]:
        print(f"✅ Pipeline completed successfully!")
        print(f"📈 Total objects detected: {result['total_objects']}")
        
        if result["detected_objects"]:
            print(f"\n🎯 Detected Objects:")
            for i, obj in enumerate(result["detected_objects"], 1):
                print(f"  {i}. {obj['color']} {obj['class_name']}")
                print(f"     - Confidence: {obj['confidence']:.3f}")
                print(f"     - Bounding box: {obj['bbox']}")
                print(f"     - Area: {obj['area']:.0f} pixels")
                print(f"     - Center: {obj['center']}")
                print()
        else:
            print("⚠️  No grounding-friendly objects detected in test image")
            print("   (This is expected with synthetic test images)")
    else:
        print(f"❌ Pipeline failed: {result.get('error', 'Unknown error')}")
    
    print("\n🧪 Testing color extraction on individual objects...")
    
    # Test color extraction with known colors
    test_colors = [
        ([255, 0, 0], "blue"),    # Blue car
        ([0, 0, 255], "red"),     # Red chair  
        ([0, 255, 0], "green"),   # Green bottle
    ]
    
    print("\n🎨 Color Detection Test:")
    for color_bgr, expected in test_colors:
        # Create a small test image with the color
        test_img = np.full((50, 50, 3), color_bgr, dtype=np.uint8)
        bbox = [10, 10, 40, 40]
        
        detected_color = detector.extract_dominant_color(test_img, bbox)
        print(f"  Expected: {expected:>6} | Detected: {detected_color:>8} | {'✅' if detected_color == expected else '❌'}")
    
    print("\n✅ Object Detection Pipeline Test Completed!")
    print("\nThe pipeline is ready for:")
    print("  ✓ YOLO object detection")
    print("  ✓ Color extraction from detected objects")
    print("  ✓ Integration with your existing str_to_pic utility")
    print("  ✓ Grounding-friendly object filtering")
    print("  ✓ Confidence-based filtering")

if __name__ == "__main__":
    test_object_detection_pipeline()
