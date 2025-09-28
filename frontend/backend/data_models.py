from pydantic import BaseModel
from typing import Optional, List, Union

class TextMessageData(BaseModel):
    text: str
    heart_rate: float
    timestamp: float 

class ImageMessageData(BaseModel):
    image: Union[str, bytes]
    heart_rate: float 
    timestamp: float

class TTSRequestData(BaseModel):
    text: str
    voice: Optional[str] = None  # Optional voice selection
    format: Optional[str] = None  # Optional audio format

class AudioProcessData(BaseModel):
    audio_data: str  # Base64 encoded audio data
    source_type: Optional[str] = "bytes"  # "bytes" or "file" 