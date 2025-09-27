import cv2
import numpy as np
import base64
from ultralytics import YOLO

class object_detection:
    def __init__(self, model_path="yolov8n.pt"):
        self.model = YOLO(model_path)

    def apply_object_detection(self,image_path):

        results = self.model(image_path) # results type = ultralytics.engine.results.Results
        return results
    
    
    def find_centers_of_class(self, result_obj, target_class: str) -> list[tuple[float, float]]:
        '''
            EXAMPLE CLASS NAMES:
            person
            laptop
            bottle
            cup
            mouse
            dining table

        '''
        """
        Find the center coordinates of all detected objects of a specified class.

        Args:
            result_obj: YOLOv8 Results object containing detections.
            target_class: Name of the object class to search for (e.g., "person", "dog").

        Returns:
            A list of (x_center, y_center) tuples for each detected object of the target class.
        """
        centers = []  # list to store center coordinates
        class_id_to_name = result_obj.names  # mapping from class IDs to class names
        bounding_boxes = result_obj.boxes.xyxy  # bounding boxes in format [x1, y1, x2, y2]

        for i, class_id in enumerate(result_obj.boxes.cls):
            class_name = class_id_to_name[int(class_id)]  # convert class ID to name
            if class_name == target_class:
                x1, y1, x2, y2 = bounding_boxes[i]
                x_center = (x1 + x2) / 2
                y_center = (y1 + y2) / 2
                centers.append((x_center.item(), y_center.item()))  # convert tensor to float

        return centers


if __name__ == "__main__":
    # Import your class (or assume it's in the same file)
    # from your_module import object_detection

    # Initialize the detector with the YOLOv8n model
    detector = object_detection()

    # Run object detection on an image
    image_path = "backend/utils/practice_data.jpg"  # change this to your image path
    results = detector.apply_object_detection(image_path)

    # YOLOv8 returns a list of Results; we'll use the first one
    result_obj = results[0]

    # Find centers of all detected "person" objects
    person_centers = detector.find_centers_of_class(result_obj, "person")

    # Print the results
    if person_centers:
        print(f"Found {len(person_centers)} person(s) at centers:")
        for idx, (x, y) in enumerate(person_centers, start=1):
            print(f"Person {idx}: (x={x:.2f}, y={y:.2f})")
    else:
        print("No persons detected in the image.")
