# server.py
from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from typing import List
import uvicorn

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/process_frame")
async def process_frame(file: UploadFile = File(...)):
    # 1. Read file
    image_bytes = await file.read()

    # 2. TODO: Run object detection
    # Replace this stub with YOLO inference
    objects_detected = ["tree", "car"]  # fake result for now
    boxes = [[50, 50, 200, 200]]        # fake bounding box

    # 3. TODO: Build prompt + call LLM
    # Replace with real API call later
    if objects_detected:
        prompt_text = f"I see some {objects_detected[0]}s. Can you count them?"
    else:
        prompt_text = "Can you take a deep breath and notice three things around you?"

    # 4. TODO: (Optional) Call TTS
    # Return text only for now
    return {
        "prompt_text": prompt_text,
        "objects_detected": objects_detected,
        "boxes": boxes
    }


# ----------------------------
# Run server
# ----------------------------
if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)
