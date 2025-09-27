from fastapi import FastAPI
# Assuming TextMessageData is in data_models.py (open on the right)
from data_models import TextMessageData, ImageMessageData
import uvicorn
#from utils import * 
#from utils import str_to_pic
from utils import llm_communication
from utils.object_detection import object_detection

app = FastAPI()

@app.get("/health")
def health():
    """Simple endpoint to confirm the server is running."""
    return {"status": "ok"}


@app.post("/upload_image")
async def process_frame(data: ImageMessageData):
    """
    Process image frame for object detection and grounding assistance.
    """
    image_string = data.image
    heart_rate = data.heart_rate
    timestamp = data.timestamp
    
    print(f"Processing image frame...")
    print(f"Heart Rate: {heart_rate} | Timestamp: {timestamp}")
    
    # Run object detection pipeline
    detection_result = obj_detector.process_image_pipeline(image_string)
    
    if detection_result["success"]:
        detected_objects = detection_result["detected_objects"]
        total_objects = detection_result["total_objects"]
        
        print(f"Detected {total_objects} objects:")
        for obj in detected_objects:
            print(f"  - {obj['color']} {obj['class_name']} (confidence: {obj['confidence']:.2f})")
        
        return {
            "status": "success",
            "detected_objects": detected_objects,
            "total_objects": total_objects,
            "message": f"Found {total_objects} grounding-friendly objects in your environment"
        }
    else:
        print(f"Detection failed: {detection_result.get('error', 'Unknown error')}")
        return {
            "status": "error",
            "error": detection_result.get("error", "Object detection failed"),
            "detected_objects": [],
            "total_objects": 0,
            "message": "I'm having trouble seeing your environment clearly. Let's focus on your breathing instead."
        }

com = llm_communication()
obj_detector = object_detection()
@app.post("/upload_text")
async def process_text(data: TextMessageData):
    text = data.text
    heart_rate = data.heart_rate
    timestamp = data.timestamp

    # Use the new enhanced pipeline with conversation history
    response = com.enhanced_message_pipeline(text, heart_rate, timestamp)
    
    print(f"input: {text}")
    print(f"heart_rate: {heart_rate}")
    print(f"RESPONSE: {response}")
    
    # Log conversation stats for monitoring
    stats = com.get_conversation_stats()
    print(f"Conversation stats: {stats}")
    
    return {"status": "success",
            "message": response}

@app.get("/conversation/stats")
async def get_conversation_stats():
    """Get conversation statistics and history info."""
    stats = com.get_conversation_stats()
    return {"status": "success", "stats": stats}

@app.post("/conversation/clear")
async def clear_conversation():
    """Clear all conversation history."""
    com.clear_conversation_history()
    return {"status": "success", "message": "Conversation history cleared"}

@app.post("/conversation/retention")
async def set_retention_period(minutes: int):
    """Set the message retention period in minutes."""
    com.set_retention_period(minutes)
    return {"status": "success", "message": f"Retention period set to {minutes} minutes"}

@app.get("/detection/test")
async def test_detection():
    """Test endpoint to verify object detection is working."""
    try:
        # This is just a health check for the detection system
        return {
            "status": "success", 
            "message": "Object detection system is ready",
            "model_loaded": True,
            "grounding_objects_count": len(obj_detector.grounding_objects)
        }
    except Exception as e:
        return {
            "status": "error",
            "message": f"Object detection system error: {str(e)}",
            "model_loaded": False
        }


# ----------------------------
# Run server
# ----------------------------
if __name__ == "__main__":
    # Note: 'server:app' tells uvicorn to look for the 'app' variable in 'server.py'
    uvicorn.run("server:app", host="0.0.0.0", port=2419, reload=True)
