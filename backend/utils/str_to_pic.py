import base64
import os
import uuid

def str_to_pic(dir: str) -> str:
    with open(dir,"r") as fp:
        imgstring=fp.read()
        if imgstring.startswith("data:image"):
            imgstring = imgstring.split(",")[1]  # remove prefix if present
        imgdata = base64.b64decode(imgstring)
        filename = f"{uuid.uuid4()}.jpg"
        return imgdata
