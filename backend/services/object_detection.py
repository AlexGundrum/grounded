import cv2
import numpy as np
import base64
from ultralytics import YOLO
import os
print(os.getcwd())


class object_detection:
    def __init__(self, model_path="yolov8n.pt"):
        self.model = YOLO(model_path)

    def apply_object_detection(self):
        results = self.model("backend/services/practice_data.jpg") # results type = ultralytics.engine.results.Results
        return results
    def count_objects_from_results(self,result_object):
        # each result within the result list
            # boxes --> detected bounding boxes
            # masks --> segmentation masks
            # probs --> probabilities of classificatino
            # orig_img --> numpy array
            # names --> dictionary mapping, 0-> "Person"
            # plot, show --> display/annotate image

       
        counts = {}
        for obj_ID in result_object.boxes.cls: # for each classified object in the list of resulting identified objects
            class_name = result_object.names[int(obj_ID)]
            counts[class_name] = counts.get(class_name, 0) + 1

        print("TEST!!!")
        for i, (box, cls, conf) in enumerate(zip(result_object.boxes.xyxy, result_object.boxes.cls, result_object.boxes.conf)):
            x1, y1, x2, y2 = box
            class_name = result_object.names[int(cls)]
            print(f"Box {i}: {class_name}, confidence={conf:.2f}, coordinates=({x1}, {y1}, {x2}, {y2})")
        return counts
    def count_and_plot_results(self, result_obj):
        """
        result_obj: single Results object
        Draws boxes on the image, prints boxes info, and returns object counts.
        """
        # Convert image to OpenCV BGR format
        img = result_obj.orig_img.copy()
        if img.shape[2] == 3:
            img_bgr = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
        else:
            img_bgr = img.copy()

        counts = {}
        for obj_ID, box, conf in zip(result_obj.boxes.cls,
                                     result_obj.boxes.xyxy,
                                     result_obj.boxes.conf):
            class_index = int(obj_ID)
            class_name = result_obj.names[class_index]
            counts[class_name] = counts.get(class_name, 0) + 1

            x1, y1, x2, y2 = map(int, box)
            label = f"{class_name} {conf:.2f}"

            # Draw rectangle
            cv2.rectangle(img_bgr, (x1, y1), (x2, y2), color=(0, 255, 0), thickness=2)
            # Draw label background
            (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 1)
            cv2.rectangle(img_bgr, (x1, y1 - h - 4), (x1 + w, y1), (0, 255, 0), -1)
            # Draw label text
            cv2.putText(img_bgr, label, (x1, y1 - 2), cv2.FONT_HERSHEY_SIMPLEX,
                        0.6, (0, 0, 0), 1, cv2.LINE_AA)

            print(f"Box: {class_name}, confidence={conf:.2f}, coordinates=({x1},{y1},{x2},{y2})")

        # Show image
        cv2.imshow("YOLO Detections", img_bgr)
        cv2.waitKey(0)
        cv2.destroyAllWindows()

        # Optionally save
        cv2.imwrite("detections_output.jpeg", img_bgr)

        return counts

if __name__ == "__main__":
    # create an instance and run detection
    detector = object_detection()  # assuming your class is ObjectDetection
    results = detector.apply_object_detection()
    result_obj = results[0]
    detector.count_objects_from_results(result_obj)
    detector.count_and_plot_results(result_obj)
