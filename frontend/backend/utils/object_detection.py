import cv2
import numpy as np
from typing import List, Dict, Any, Optional
from ultralytics import YOLO
import os
from .str_to_pic import str_to_pic
import time

class object_detection:
    def __init__(self, model_name: str = "yolov8n.pt"):
        """
        Initialize the YOLO object detection pipeline.
        
        Args:
            model_name: YOLO model to use (yolov8n.pt, yolov8s.pt, yolov8m.pt, yolov8l.pt, yolov8x.pt)
        """
        self.model = YOLO(model_name)
        
        # COCO class names for reference
        self.coco_classes = {
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
        
        # Grounding-friendly objects (objects that are good for grounding exercises)
        self.grounding_objects = {
            'person', 'car', 'bicycle', 'motorcycle', 'bus', 'truck', 'boat',
            'bird', 'cat', 'dog', 'horse', 'cow', 'elephant', 'bear',
            'bottle', 'cup', 'bowl', 'chair', 'couch', 'bed', 'tv',
            'laptop', 'book', 'clock', 'vase', 'teddy bear', 'backpack',
            'handbag', 'suitcase', 'potted plant', 'tree', 'flower'
        }
    
        self.last_objects_identified = None
    
    def apply_object_detection(self, image_str: str): #handles image casting and gets result obj
        image_path = str_to_pic(image_str)
        image = cv2.imread(image_path)
        results = self.model(image) # results type = ultralytics.engine.results.Results
        return results
    
    def extract_dominant_color(self, image: np.ndarray, bbox: List[int]) -> str:
        """
        Extract the dominant color from a bounding box region.
        
        Args:
            image: OpenCV image array
            bbox: Bounding box [x1, y1, x2, y2]
            
        Returns:
            Color name as string
        """
        try:
            x1, y1, x2, y2 = map(int, bbox)
            # Ensure coordinates are within image bounds
            x1 = max(0, x1)
            y1 = max(0, y1)
            x2 = min(image.shape[1], x2)
            y2 = min(image.shape[0], y2)
            
            # Extract region of interest
            roi = image[y1:y2, x1:x2]
            
            if roi.size == 0:
                return "unknown"
            
            # Convert to HSV for better color analysis
            hsv = cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)
            
            # Calculate mean color
            mean_color = np.mean(hsv, axis=(0, 1))
            hue, saturation, value = mean_color
            
            # Map HSV to color names
            return self._hsv_to_color_name(hue, saturation, value)
            
        except Exception as e:
            print(f"Error extracting color: {e}")
            return "unknown"
    
    def _hsv_to_color_name(self, hue: float, saturation: float, value: float) -> str:
        """
        Convert HSV values to color names.
        
        Args:
            hue: Hue value (0-179)
            saturation: Saturation value (0-255)
            value: Value/Brightness (0-255)
            
        Returns:
            Color name string
        """
        # Adjust hue to 0-360 range
        hue = hue * 2
        
        # Very low saturation = gray/white/black
        if saturation < 30:
            if value < 85:
                return "black"
            elif value > 170:
                return "white"
            else:
                return "gray"
        
        # High saturation colors
        if 0 <= hue < 15 or 345 <= hue <= 360:
            return "red"
        elif 15 <= hue < 45:
            return "orange"
        elif 45 <= hue < 75:
            return "yellow"
        elif 75 <= hue < 165:
            return "green"
        elif 165 <= hue < 195:
            return "cyan"
        elif 195 <= hue < 255:
            return "blue"
        elif 255 <= hue < 285:
            return "purple"
        elif 285 <= hue < 345:
            return "pink"
        else:
            return "unknown"
    
    def detect_objects_with_colors(self, image_path: str, confidence_threshold: float = 0.5) -> List[Dict[str, Any]]:
        """
        Detect objects in image using YOLO and extract their colors.
        
        Args:
            image_path: Path to the image file
            confidence_threshold: Minimum confidence for detection
            
        Returns:
            List of detected objects with their properties
        """
        try:
            # Load image
            image = cv2.imread(image_path)
            if image is None:
                print(f"Error: Could not load image from {image_path}")
                return []
            
            # Run YOLO detection
            results = self.model(image, conf=confidence_threshold)
            
            detected_objects = []
            
            for result in results:
                boxes = result.boxes
                if boxes is not None:
                    for i, box in enumerate(boxes):
                        # Extract bounding box coordinates
                        x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                        confidence = float(box.conf[0].cpu().numpy())
                        class_id = int(box.cls[0].cpu().numpy())
                        
                        # Get class name
                        class_name = self.coco_classes.get(class_id, f"class_{class_id}")
                        
                        # Skip if not a grounding-friendly object
                        if class_name not in self.grounding_objects:
                            continue
                        
                        # Extract dominant color
                        color = self.extract_dominant_color(image, [x1, y1, x2, y2])
                        
                        detected_object = {
                            "class_name": class_name,
                            "confidence": confidence,
                            "bbox": [float(x1), float(y1), float(x2), float(y2)],
                            "color": color,
                            "center": [float((x1 + x2) / 2), float((y1 + y2) / 2)],
                            "area": float((x2 - x1) * (y2 - y1))
                        }
                        
                        detected_objects.append(detected_object)
            
            # Sort by area (largest objects first) for better grounding
            detected_objects.sort(key=lambda x: x["area"], reverse=True)
            
            return detected_objects
            
        except Exception as e:
            print(f"Error in object detection: {e}")
            return []
    
    def process_image_pipeline(self, image_string: str, confidence_threshold: float = 0.5) -> Dict[str, Any]:
        """
        Complete image processing pipeline: string -> image file -> detect -> extract colors.
        
        Args:
            image_string: Base64 encoded image string
            confidence_threshold: YOLO confidence threshold
            
        Returns:
            Dictionary with detection results
        """
        try:
            # Convert string to image file using existing utility
            image_path = str_to_pic(image_string)
            
            # Detect objects with colors
            detected_objects = self.detect_objects_with_colors(image_path, confidence_threshold)
            
            # Clean up the temporary image file
            try:
                os.remove(image_path)
            except:
                pass
            
            return {
                "success": True,
                "detected_objects": detected_objects,
                "total_objects": len(detected_objects)
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "detected_objects": [],
                "total_objects": 0
            }
    
    
    def get_objects_from_results_for_kori(self, result_obj, frame_count, start_time,confidence_threshold: float = 0.5):
        """
        Extracts detected objects in the format:
        {
            "class_id": int,
            "box_x": int,
            "box_y": int,
            "confidence": float,
            "processing_time": float,
            "frame_id": int,
            "status": "success"
        }
        Only includes objects above the confidence threshold.
        """
        detections = []
        class_id_to_name = result_obj.names
        boxes = result_obj.boxes.xyxy
        class_ids = result_obj.boxes.cls
        confidences = result_obj.boxes.conf

        for i, class_id in enumerate(class_ids):
            confidence = confidences[i].item()
            if confidence < confidence_threshold:
                continue

            class_name = class_id_to_name[int(class_id)]
            x1, y1, x2, y2 = boxes[i]

            # Compute center as integers
            center_x = int(((x1 + x2) / 2).item())
            center_y = int(((y1 + y2) / 2).item())

            # Get class_id from COCO dictionary
            name_to_id = {v: k for k, v in self.coco_classes.items()}
            class_id_int = name_to_id[class_name]

            detections.append({
                "class_id": class_id_int,
                "box_x": center_x,
                "box_y": center_y,
                "confidence": round(confidence, 3),
                "processing_time": round(time.time() - start_time, 3),
                "frame_id": frame_count,
                "status": "success"
            })
        self.last_objects_identified = detections
        return {"objects": detections}


