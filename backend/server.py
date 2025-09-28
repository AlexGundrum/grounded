from fastapi import FastAPI, HTTPException, Request, Depends
# Assuming TextMessageData is in data_models.py (open on the right)
from data_models import TextMessageData, ImageMessageData, TTSRequestData, AudioProcessData
import uvicorn
import time
from typing import Dict, Tuple
#from utils import * 
#from utils import str_to_pic
from utils.llm_communication import llm_communication
from utils.object_detection import object_detection
from services.text_to_speech import text_to_speech

app = FastAPI()

# Rate limiting for upload_text endpoint
# Track last request timestamps by client (using IP or session)
last_request_times: Dict[str, float] = {}
RATE_LIMIT_SECONDS = 5  # Minimum seconds between requests (adjust as needed)

# Cumulative object detection results - accumulates all objects seen over time
cumulative_detected_objects: set = set()

def get_client_id(request) -> str:
    """
    Generate a client identifier for rate limiting.
    Uses IP address as the primary identifier.
    """
    # Get client IP address
    client_ip = request.client.host if request.client else "unknown"
    return client_ip

def check_rate_limit(client_id: str) -> Tuple[bool, float]:
    """
    Check if client is within rate limit.
    
    Returns:
        (is_allowed, time_since_last_request)
    """
    current_time = time.time()
    
    # Clean up old entries (older than 10 minutes) to prevent memory leaks
    cleanup_old_entries(current_time)
    
    if client_id in last_request_times:
        time_since_last = current_time - last_request_times[client_id]
        if time_since_last < RATE_LIMIT_SECONDS:
            return False, time_since_last
    
    # Update timestamp
    last_request_times[client_id] = current_time
    return True, 0.0

def cleanup_old_entries(current_time: float):
    """
    Remove entries older than 10 minutes to prevent memory leaks.
    """
    cutoff_time = current_time - (10 * 60)  # 10 minutes ago
    old_keys = [key for key, timestamp in last_request_times.items() if timestamp < cutoff_time]
    for key in old_keys:
        del last_request_times[key]

def rate_limit_check(request: Request):
    """
    Dependency function for rate limiting that can be injected into endpoints.
    """
    client_id = get_client_id(request)
    is_allowed, time_since_last = check_rate_limit(client_id)
    
    if not is_allowed:
        remaining_time = RATE_LIMIT_SECONDS - time_since_last
        print(f"Rate limit exceeded for client {client_id}. Please wait {remaining_time:.1f} seconds.")
        raise HTTPException(
            status_code=429, 
            detail=f"Rate limit exceeded. Please wait {remaining_time:.1f} seconds before making another request."
        )
    
    return client_id

@app.get("/health")
def health():
    """Simple endpoint to confirm the server is running."""
    return {"status": "ok"}

detector = object_detection(model_name="yolov8n.pt")
frame_counter = 0

def get_last_objects_identified():
    return detector.last_objects_identified

def add_to_cumulative_objects(object_names: list):
    """Add new object names to the cumulative detected objects set."""
    global cumulative_detected_objects
    for obj_name in object_names:
        if obj_name and obj_name.strip():  # Only add non-empty strings
            cumulative_detected_objects.add(obj_name.strip().lower())

def get_cumulative_objects():
    """Get all objects that have been detected over time."""
    global cumulative_detected_objects
    return list(cumulative_detected_objects)

@app.put("/detection/image_qualities")
async def detect_object_data_from_photo(data: ImageMessageData):
    global frame_counter
    frame_counter +=1
    
    start_time = time.time()
    image_string = data.image
    results = detector.apply_object_detection(image_string) 
    formatted_results = detector.get_objects_from_results_for_kori(results[0], frame_counter,start_time,confidence_threshold= 0.5) 
    detector.last_objects_identified = formatted_results
    return formatted_results
    # Convert to Kori's desired format
    
    #file uploaded is an image


@app.post("/upload_image")
async def process_frame(data: ImageMessageData):
    #print("Raw data:", data.model_dump())
    #print("Raw data:", data.model_dump_json())
    global frame_counter
    frame_counter +=1
    #print("starting object detection n logic")
    start_time = time.time()
    image_string = data.image
    
    # DEBUG: Save received image for inspection
    try:
        import base64
        import os
        from datetime import datetime
        
        # Create debug directory if it doesn't exist
        debug_dir = "debug_images"
        if not os.path.exists(debug_dir):
            os.makedirs(debug_dir)
        
        # Generate filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{debug_dir}/received_image_{frame_counter}_{timestamp}.jpg"
        
        # Decode and save the image
        image_data = base64.b64decode(image_string)
        with open(filename, 'wb') as f:
            f.write(image_data)
        
        #print(f"DEBUG: Saved received image to {filename}")
        #print(f"DEBUG: Image size: {len(image_data)} bytes")
        
    except Exception as e:
        print(f"DEBUG: Failed to save image: {e}")
        print(f"DEBUG: Image string length: {len(image_string)}")
        print(f"DEBUG: Image string preview: {image_string[:100]}...")
    
    results = detector.apply_object_detection(image_string) 
    formatted_results = detector.get_objects_from_results_for_kori(results[0], frame_counter,start_time,confidence_threshold= 0.5) 
    if formatted_results is not None:
        detector.last_objects_identified = formatted_results
        
        # Extract object names and add to cumulative list
        object_names = []
        for obj in formatted_results:
            if isinstance(obj, dict) and 'object' in obj:
                object_names.append(obj['object'])
            elif isinstance(obj, str):
                object_names.append(obj)
        
        # Add new objects to cumulative list
        add_to_cumulative_objects(object_names)
        print(f"Cumulative objects so far: {get_cumulative_objects()}")

    end_time = time.time()
    #print("  zach's formatted restults: " +  str(formatted_results) + " and Took : " + str(end_time - start_time) + " seconds")
    return formatted_results

com = llm_communication()
obj_detector = object_detection()
tts_service = text_to_speech()

@app.post("/start-new-anxiety")
def set_therapy_stage_to_zero():
    com.current_stage = 0

@app.post("/upload_text") #FIXME we have client id and it doesn't get used.
async def process_text(data: TextMessageData, client_id: str = Depends(rate_limit_check)):
    
    text = data.text
    heart_rate = data.heart_rate
    timestamp = data.timestamp

    # Use the new enhanced pipeline with conversation history
    #response = com.enhanced_message_pipeline(text, timestamp)
    

    # Get all cumulative object detection results for grounding exercise
    od_object_names = get_cumulative_objects()
    print(f"Using cumulative objects for grounding: {od_object_names}")
    

    #FIXME FIXME FIXME this is where we will call our direction function in llm comm


    #FIXME ALEX if there is a problem it is likely due to this lazy interchange im about to do 
   # response = com.process_grounding_exercise(text, timestamp, od_results=od_object_names)
    response = com.starting_point(text, timestamp, od_results=od_object_names)


    print(f"input: {text}")
    print(f"heart_rate: {heart_rate}")
    print(f"RESPONSE: {response}")
    
    # Log conversation stats for monitoring
    #stats = com.get_conversation_stats()
    #print(f"Conversation stats: {stats}")
    
    # Convert LLM response to speech using TTS
    try:
        print(f"Converting response to speech...")
        tts_result = tts_service.create_grounding_audio(response)
        
        if tts_result["success"]:
            print(f"✅ TTS conversion successful!")
            #print(f"Voice used: {tts_result['voice_used']}")
            string_message = tts_result["audio_data"]
            #print(f"long string ass message: {string_message}")
            return {
                "status": "success",
                "message": response,
                "audio_base64": tts_result["audio_data"]
            }
        else:
            print(f"❌ TTS conversion failed: {tts_result['error']}")
            # Return text response even if TTS fails
            return {
                "status": "success",
                "message": response,
                "audio_base64": None
            }
        
    except Exception as e:
        print(f"❌ TTS service error: {e}")
        # Return text response even if TTS fails
        return {
            "status": "success",
            "message": response,
            "audio_base64": None
        }

# ----------------------------
# Run server
# ----------------------------
if __name__ == "__main__":
    # Note: 'server:app' tells uvicorn to look for the 'app' variable in 'server.py'
    uvicorn.run("server:app", host="0.0.0.0", port=2419, reload=True)
