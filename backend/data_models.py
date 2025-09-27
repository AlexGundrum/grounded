from pydantic import BaseModel
from typing import Optional, List

class TextMessageData(BaseModel):
    text: str
    heart_rate: float
    timestamp: float 

class ImageMessageData(BaseModel):
    image: str 
    heart_rate: float 
    timestamp: float 