from fastapi import FastAPI, HTTPException, Request, Depends
# Assuming TextMessageData is in data_models.py (open on the right)
from data_models import TextMessageData, ImageMessageData, TTSRequestData, AudioProcessData
import uvicorn
import time
from typing import Dict, Tuple
#from utils import * 
#from utils import str_to_pic
from utils import llm_communication
from utils.object_detection import object_detection
from services.text_to_speech import text_to_speech

app = FastAPI()

# Rate limiting for upload_text endpoint
# Track last request timestamps by client (using IP or session)
last_request_times: Dict[str, float] = {}
RATE_LIMIT_SECONDS = 5  # Minimum seconds between requests (adjust as needed)

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




@app.get("/rate-limit/status")
async def get_rate_limit_status(request: Request):
    """Get rate limit status for the current client."""
    client_id = get_client_id(request)
    current_time = time.time()
    
    if client_id in last_request_times:
        time_since_last = current_time - last_request_times[client_id]
        remaining_time = max(0, RATE_LIMIT_SECONDS - time_since_last)
        is_allowed = remaining_time == 0
    else:
        time_since_last = 0
        remaining_time = 0
        is_allowed = True
    
    return {
        "client_id": client_id,
        "rate_limit_seconds": RATE_LIMIT_SECONDS,
        "is_allowed": is_allowed,
        "time_since_last_request": time_since_last,
        "remaining_wait_time": remaining_time
    }


@app.post("/upload_image")
async def process_frame(data: ImageMessageData):
    pass
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
tts_service = text_to_speech()

@app.post("/start-new-anxiety")
def set_therapy_stage_to_zero():
    com.current_stage = 0

@app.post("/upload_text")
async def process_text(data: TextMessageData, client_id: str = Depends(rate_limit_check)):
    
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

@app.post("/tts/convert")
async def convert_text_to_speech(data: TTSRequestData):
    """
    Convert text to speech using OpenAI's TTS API and return base64 audio.
    """
    try:
        text = data.text
        voice = data.voice
        format = data.format
        
        print(f"Converting text to speech: '{text[:50]}...'")
        if voice:
            print(f"Using voice: {voice}")
        
        # Convert text to audio
        result = tts_service.process_text_pipeline(text, voice=voice)
        
        if result["success"]:
            return {
                "status": "success",
                "audio_data": result["audio_data"],
                "voice_used": result["voice_used"],
                "voice_description": result["voice_description"],
                "text_length": result["text_length"],
                "format": result["format"],
                "message": "Text successfully converted to speech"
            }
        else:
            return {
                "status": "error",
                "error": result["error"],
                "audio_data": None,
                "message": "Failed to convert text to speech"
            }
            
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "audio_data": None,
            "message": "TTS service error"
        }

@app.get("/tts/voices")
async def get_available_voices():
    """Get list of available TTS voices and their descriptions."""
    try:
        voices = tts_service.get_available_voices()
        return {
            "status": "success",
            "voices": voices,
            "default_voice": tts_service.default_voice,
            "available_formats": tts_service.available_formats,
            "default_format": tts_service.default_format
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "voices": {}
        }

@app.post("/tts/grounding")
async def create_grounding_audio(data: TTSRequestData):
    """
    Create audio specifically optimized for anxiety grounding exercises.
    Uses calming voice and optimized settings.
    """
    try:
        text = data.text
        voice = data.voice  # Optional override
        
        print(f"Creating grounding audio: '{text[:50]}...'")
        
        # Create grounding audio
        result = tts_service.create_grounding_audio(text, voice=voice)
        
        if result["success"]:
            return {
                "status": "success",
                "audio_data": result["audio_data"],
                "voice_used": result["voice_used"],
                "voice_description": result["voice_description"],
                "text_length": result["text_length"],
                "format": result["format"],
                "message": "Grounding audio created successfully"
            }
        else:
            return {
                "status": "error",
                "error": result["error"],
                "audio_data": None,
                "message": "Failed to create grounding audio"
            }
            
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "audio_data": None,
            "message": "Grounding audio service error"
        }

@app.post("/audio/encode")
async def encode_audio_to_base64(data: AudioProcessData):
    """
    Convert audio data (bytes or file) to base64 encoded string.
    """
    try:
        audio_input = data.audio_data
        source_type = data.source_type or "bytes"
        
        print(f"Processing audio data for base64 encoding...")
        print(f"Source type: {source_type}")
        
        # Convert source_type to boolean for is_file_path parameter
        is_file_path = (source_type == "file")
        
        # Process audio data
        result = tts_service.process_audio_pipeline(audio_input, is_file_path=is_file_path)
        
        if result["success"]:
            return {
                "status": "success",
                "audio_data": result["audio_data"],
                "source": result["source"],
                "audio_size_bytes": result["audio_size_bytes"],
                "message": "Audio successfully encoded to base64"
            }
        else:
            return {
                "status": "error",
                "error": result["error"],
                "audio_data": None,
                "message": "Failed to encode audio to base64"
            }
            
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "audio_data": None,
            "message": "Audio encoding service error"
        }

@app.post("/audio/process")
async def process_audio_file(file_path: str):
    """
    Process an audio file and return its base64 encoding.
    Alternative endpoint that takes file path directly.
    """
    try:
        print(f"Processing audio file: {file_path}")
        
        # Process audio file
        result = tts_service.process_audio_pipeline(file_path, is_file_path=True)
        
        if result["success"]:
            return {
                "status": "success", 
                "audio_data": result["audio_data"],
                "file_path": result["file_path"],
                "audio_size_bytes": result["audio_size_bytes"],
                "message": "Audio file successfully processed"
            }
        else:
            return {
                "status": "error",
                "error": result["error"],
                "audio_data": None,
                "message": "Failed to process audio file"
            }
            
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "audio_data": None,
            "message": "Audio file processing error"
        }


# ----------------------------
# Run server
# ----------------------------
if __name__ == "__main__":
    # Note: 'server:app' tells uvicorn to look for the 'app' variable in 'server.py'
    uvicorn.run("server:app", host="0.0.0.0", port=2419, reload=True)
