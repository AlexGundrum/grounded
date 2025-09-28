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
    def apply_object_detection(self,image_str: str): #handles image casting and gets result obj
        image_path = str_to_pic(image_str)
        image = cv2.imread(image_path)
        results = self.model(image_str) # results type = ultralytics.engine.results.Results
        return results
    
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

        return {"objects": detections}
    

    def save_snippets(self,image_path, detections, output_dir="snippets"):
        """
        Crop detected objects from the image and save as snippets.

        Args:
            image_path (str): Path to the original image.
            detections (list): List of dicts, each with keys 'class', 'center', 'box_width', 'box_height'.
            output_dir (str): Directory where snippets will be saved.
        """
        # Load the image
        image = cv2.imread(image_path)
        if image is None:
            raise ValueError(f"Could not read image at {image_path}")

        # Create output dir if not exists
        os.makedirs(output_dir, exist_ok=True)

        list_snip=[]

        for i, det in enumerate(detections):
            x_center, y_center = det["center"]
            w, h = det["box_width"], det["box_height"]

            # Convert center+wh to top-left and bottom-right
            x1 = int(x_center - w / 2)
            y1 = int(y_center - h / 2)
            x2 = int(x_center + w / 2)
            y2 = int(y_center + h / 2)

            # Clip to image boundaries
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(image.shape[1] - 1, x2), min(image.shape[0] - 1, y2)

            # Crop snippet
            snippet = image[y1:y2, x1:x2]

            list_snip.append(snippet)
            # Save snippet
            # filename = f"{det['class']}_{i}.jpg"
            # save_path = os.path.join(output_dir, filename)
            # cv2.imwrite(save_path, snippet)

            # print(f"Saved {save_path}")

        return list_snip



    def rgb_to_hex(self, rgb):
        return "#{:02x}{:02x}{:02x}".format(rgb[0], rgb[1], rgb[2])

    def get_dominant_colors_text(self, img, k=5):
        # Load image (BGR)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        # Reshape to a list of pixels
        pixels = img.reshape((-1, 3))

        # Run KMeans clustering
        kmeans = KMeans(n_clusters=k, random_state=42)
        kmeans.fit(pixels)

        # Get cluster centers
        colors = kmeans.cluster_centers_.astype(int)

        # Sort by frequency
        labels, counts = np.unique(kmeans.labels_, return_counts=True)
        sorted_idx = np.argsort(-counts)
        colors = colors[sorted_idx]

        # Build text output
        output = []
        for idx, c in enumerate(colors, 1):
            rgb = tuple(c)
            output.append(rgb)

        return output

    def rgb_to_common_color(self, rgb_list):
        """
        Map a list of RGB values to the closest common color names.

        Args:
            rgb_list (list of tuples): [(R, G, B), ...]

        Returns:
            list of str: Closest color names
        """

        # Define a palette of 10 common colors
        common_colors = {
            "red": (255, 0, 0),
            "orange": (255, 165, 0),
            "yellow": (255, 255, 0),
            "green": (0, 128, 0),
            "blue": (0, 0, 255),
            "purple": (128, 0, 128),
            "brown": (165, 42, 42),
            "black": (0, 0, 0),
            "white": (255, 255, 255),
        }

        # Convert palette to numpy for vectorized distance
        color_names = list(common_colors.keys())
        color_values = np.array(list(common_colors.values()))

        results = []
        for rgb in rgb_list:
            rgb_arr = np.array(rgb)
            distances = np.linalg.norm(color_values - rgb_arr, axis=1)
            closest_idx = np.argmin(distances)
            results.append(color_names[closest_idx])

        return results

    def color_extract(self, photo_dir,raw_data):
        # photo_dir="C:\\projects\\gt12\\grounded\\backend\\utils\\d7ff70b8-5f01-4459-ac44-550358dc3977.jpg"
        color_list=set([])
        snp_list=self.save_snippets(photo_dir,raw_data)
        for i in snp_list:
            tmp=self.get_dominant_colors_text(i)
            tmp_col_list=self.rgb_to_common_color(tmp)
            for j in tmp_col_list:
                color_list.add(j)
        return color_list
    
    


