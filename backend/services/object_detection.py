import cv2
import numpy as np
import os
from ultralytics import YOLO
import matplotlib.pyplot as plt

print(os.getcwd())

class object_detection:
    def __init__(self, model_path="yolov8n.pt"):
        self.model = YOLO(model_path)

    def apply_object_detection(self, img_path="backend/services/practice_data.jpg"):
        # Load original image directly (RGB)
        self.img_rgb = cv2.cvtColor(cv2.imread(img_path), cv2.COLOR_BGR2RGB)
        results = self.model(img_path)  # YOLO detection
        return results

    def count_objects_from_results(self, result_object):
        counts = {}
        for obj_ID in result_object.boxes.cls:
            class_name = result_object.names[int(obj_ID)]
            counts[class_name] = counts.get(class_name, 0) + 1

        for i, (box, cls, conf) in enumerate(zip(result_object.boxes.xyxy,
                                                 result_object.boxes.cls,
                                                 result_object.boxes.conf)):
            x1, y1, x2, y2 = box
            class_name = result_object.names[int(cls)]
            print(f"Box {i}: {class_name}, confidence={conf:.2f}, coordinates=({x1}, {y1}, {x2}, {y2})")
        return counts

    # COLOR METHODS DO NOT WORK AT ALL LOLOLOLOL
    @staticmethod
    def get_basic_color_from_hsv(avg_rgb):
        # Convert RGB -> BGR -> HSV
        bgr_pixel = np.uint8([[avg_rgb[::-1]]])
        h, s, v = cv2.cvtColor(bgr_pixel, cv2.COLOR_BGR2HSV)[0][0]

        if v < 50:
            return "black"
        elif v > 200 and s < 50:
            return "white"
        elif s < 50:
            return "gray"
        elif h < 15 or h >= 165:
            return "red"
        elif 15 <= h < 35:
            return "orange"
        elif 35 <= h < 55:
            return "yellow"
        elif 55 <= h < 100:
            return "green"
        elif 100 <= h < 130:
            return "blue"
        elif 130 <= h < 160:
            return "violet"
        else:
            return "unknown"

    def list_of_colors_from_boxed_objects(self, result_object):
        colors = []

        for box in result_object[0].boxes:
            x1, y1, x2, y2 = box.xyxy[0].int().tolist()
            crop_rgb = self.img_rgb[y1:y2, x1:x2]

            if crop_rgb.size > 0:
                avg_rgb = tuple(np.round(crop_rgb.mean(axis=(0, 1))).astype(int))
                color_name = self.get_basic_color_from_hsv(avg_rgb)
            else:
                color_name = "unknown"

            colors.append(color_name)

        return colors

    def count_and_plot_results(self, result_obj, use_matplotlib=False):
        img_bgr = cv2.cvtColor(self.img_rgb, cv2.COLOR_RGB2BGR)  # BGR for OpenCV drawing
        counts = {}
        colors = self.list_of_colors_from_boxed_objects(result_obj)

        for i, (obj_ID, box, conf) in enumerate(zip(result_obj.boxes.cls,
                                                    result_obj.boxes.xyxy,
                                                    result_obj.boxes.conf)):
            class_index = int(obj_ID)
            class_name = result_obj.names[class_index]
            counts[class_name] = counts.get(class_name, 0) + 1

            x1, y1, x2, y2 = map(int, box)
            color_name = colors[i] if i < len(colors) else "unknown"

            label = f"{class_name} {conf:.2f} ({color_name})"

            # Draw rectangle
            cv2.rectangle(img_bgr, (x1, y1), (x2, y2), color=(0, 255, 0), thickness=2)

            # Draw label background
            (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 1)
            cv2.rectangle(img_bgr, (x1, y1 - h - 4), (x1 + w, y1), (0, 255, 0), -1)

            # Draw label text
            cv2.putText(img_bgr, label, (x1, y1 - 2), cv2.FONT_HERSHEY_SIMPLEX,
                        0.6, (0, 0, 0), 1, cv2.LINE_AA)

            print(f"Box: {class_name}, confidence={conf:.2f}, coordinates=({x1},{y1},{x2},{y2}), color={color_name}")

        if use_matplotlib:
            plt.imshow(self.img_rgb)
            plt.axis("off")
            plt.show()
        else:
            cv2.imshow("YOLO Detections", img_bgr)
            cv2.waitKey(0)
            cv2.destroyAllWindows()

        # Save output
        cv2.imwrite("detections_output.jpeg", img_bgr)
        return counts

if __name__ == "__main__":
    detector = object_detection()
    results = detector.apply_object_detection()
    result_obj = results[0]
    detector.count_objects_from_results(result_obj)
    detector.count_and_plot_results(result_obj, use_matplotlib=False)  # True = proper RGB display
