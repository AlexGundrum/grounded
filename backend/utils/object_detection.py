import cv2
import numpy as np
import base64
from ultralytics import YOLO

class object_detection:
    def __init__(self, model_path="yolov8n.pt"):
        self.model = YOLO(model_path)

    def apply_object_detection(self):
        results = self.model("backend/utils/puppy.jpg") # results type = ultralytics.engine.results.Results
        return results
    def count_objects_from_results(self,list_of_results):
        # each result within the result list
            # boxes --> detected bounding boxes
            # masks --> segmentation masks
            # probs --> probabilities of classificatino
            # orig_img --> numpy array
            # names --> dictionary mapping, 0-> "Person"
            # plot, show --> display/annotate image

        list_of_object_IDs = result.boxes.cls  # list of predicted/identified objects
        index_to_name = result.names # index -> obj_type name
        obj_names = [ index_to_name[int(c)] for c in index_to_name]

        result = {}
        for obj_ID in list_of_object_IDs: # for each classified object in the list of resulting identified objects
            name = index_to_name[obj_ID]
            result[name] = result.get(name, 0) + 1

            
        return result