from fastapi import FastAPI
# Assuming TextMessageData is in data_models.py (open on the right)
from data_models import TextMessageData, ImageMessageData
import uvicorn
#from utils import * 
#from utils import str_to_pic
from utils import llm_communication

app = FastAPI()

@app.get("/health")
def health():
    """Simple endpoint to confirm the server is running."""
    return {"status": "ok"}


@app.post("/upload_image")
async def process_frame(data: ImageMessageData):
    pass

com = llm_communication()
@app.post("/upload_text")
async def process_text(data: TextMessageData):
    text = data.text
    heart_rate = data.heart_rate
    timestamp = data.timestamp

    response = com.new_message_protocol(text)
    print(f"input: {text}")
    print(f"RESPONSE: {response}")
    return {"status": "success",
            "message" : response}

    if heart_rate > 100:
        print(f"CRITICAL: High heart rate detected ({heart_rate} bpm)!")

    print(f"--- Received Log Entry ---")
    print(f"Text: {text}")
    print(f"HR: {heart_rate} | Timestamp: {timestamp}")
    print(f"--------------------------")
    
    return {
        "status": "success", 
        "message": f"TTS is confirmed to speak the text: {text}"
    }


# ----------------------------
# Run server
# ----------------------------
if __name__ == "__main__":
    # Note: 'server:app' tells uvicorn to look for the 'app' variable in 'server.py'
    uvicorn.run("server:app", host="0.0.0.0", port=2419, reload=True)
