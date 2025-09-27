import base64
import os
import uuid

def str_to_pic(imgstring: str) -> str:
    if imgstring.startswith("data:image"):
        imgstring = imgstring.split(",")[1]  # remove prefix if present
    imgdata = base64.b64decode(imgstring)
    filename = f"{uuid.uuid4()}.jpg"
    with open(filename, "wb") as f:
        f.write(imgdata)
    return filename
