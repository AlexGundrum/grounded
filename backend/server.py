# server.py
from fastapi import FastAPI, UploadFile, File, Body
from pydantic import BaseModel
from typing import List
import uvicorn
from utils import * 
app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/upload_image")
async def process_frame():
    pass

@app.post("/upload_text")
async def process_text(text: str = Body(..., embed=True, alias="prompt_text")):
    print(f"Received simple text: {text}")
    
    return {
        "status": "success", 
        "message": f"TTS engine is speaking the text: {text}"
    }



# ----------------------------
# Run server
# ----------------------------
if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=2419, reload=True)
