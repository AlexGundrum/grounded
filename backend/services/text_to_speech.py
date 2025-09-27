import os
import base64
import io
from typing import Optional
from openai import OpenAI

class text_to_speech:
    def __init__(self):
        """
        Initialize the text-to-speech service using OpenAI's TTS API.
        """
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        
        # Available voices for grounding/calming speech
        self.available_voices = {
            "alloy": "Neutral, calm voice",
            "echo": "Warm, friendly voice", 
            "fable": "Soft, gentle voice",
            "onyx": "Deep, reassuring voice",
            "nova": "Bright, uplifting voice",
            "shimmer": "Light, soothing voice"
        }
        
        # Default voice for anxiety grounding (calm and soothing)
        self.default_voice = "shimmer"
        
        # Available audio formats
        self.available_formats = ["mp3", "opus", "aac", "flac"]
        self.default_format = "mp3"
    
    def text_to_audio(self, text: str, voice: str = None, format: str = None) -> Optional[str]:
        """
        Convert text to audio using OpenAI's TTS API and return as base64 string.
        
        Args:
            text: Text to convert to speech
            voice: Voice to use (default: shimmer for calming effect)
            format: Audio format (default: mp3)
            
        Returns:
            Base64 encoded audio string or None if failed
        """
        try:
            # Use defaults if not specified
            if voice is None:
                voice = self.default_voice
            if format is None:
                format = self.default_format
            
            # Validate voice and format
            if voice not in self.available_voices:
                print(f"Warning: Voice '{voice}' not available, using default")
                voice = self.default_voice
            
            if format not in self.available_formats:
                print(f"Warning: Format '{format}' not available, using default")
                format = self.default_format
            
            # Call OpenAI TTS API
            response = self.client.audio.speech.create(
                model="tts-1",  # or "tts-1-hd" for higher quality
                voice=voice,
                input=text,
                response_format=format
            )
            
            # Get audio data
            audio_data = response.content
            
            # Convert to base64
            audio_base64 = base64.b64encode(audio_data).decode('utf-8')
            
            return audio_base64
            
        except Exception as e:
            print(f"Error in text-to-speech conversion: {e}")
            return None
    
    def get_available_voices(self) -> dict:
        """
        Get list of available voices and their descriptions.
        
        Returns:
            Dictionary of voice names and descriptions
        """
        return self.available_voices.copy()
    
    def get_voice_description(self, voice: str) -> str:
        """
        Get description for a specific voice.
        
        Args:
            voice: Voice name
            
        Returns:
            Voice description or "Unknown voice"
        """
        return self.available_voices.get(voice, "Unknown voice")
    
    def create_grounding_audio(self, grounding_prompt: str, voice: str = None) -> dict:
        """
        Create audio specifically for anxiety grounding with appropriate voice selection.
        
        Args:
            grounding_prompt: The grounding text/prompt to convert
            voice: Specific voice to use (optional)
            
        Returns:
            Dictionary with audio data and metadata
        """
        try:
            # Use calming voice for grounding exercises
            if voice is None:
                voice = self.default_voice
            
            # Convert text to audio
            audio_base64 = self.text_to_audio(grounding_prompt, voice=voice)
            
            if audio_base64 is None:
                return {
                    "success": False,
                    "error": "Failed to generate audio",
                    "audio_data": None,
                    "voice_used": voice
                }
            
            return {
                "success": True,
                "audio_data": audio_base64,
                "voice_used": voice,
                "voice_description": self.get_voice_description(voice),
                "text_length": len(grounding_prompt),
                "format": self.default_format
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "audio_data": None,
                "voice_used": voice if voice else self.default_voice
            }
    
    def audio_to_base64(self, audio_data: bytes) -> Optional[str]:
        """
        Convert audio data (bytes) to base64 encoded string.
        
        Args:
            audio_data: Raw audio data as bytes
            
        Returns:
            Base64 encoded audio string or None if failed
        """
        try:
            if not audio_data:
                return None
            
            # Convert to base64
            audio_base64 = base64.b64encode(audio_data).decode('utf-8')
            return audio_base64
            
        except Exception as e:
            print(f"Error converting audio to base64: {e}")
            return None
    
    def file_to_base64(self, file_path: str) -> Optional[str]:
        """
        Read audio file and convert to base64 encoded string.
        
        Args:
            file_path: Path to the audio file
            
        Returns:
            Base64 encoded audio string or None if failed
        """
        try:
            if not os.path.exists(file_path):
                print(f"Audio file not found: {file_path}")
                return None
            
            # Read file as bytes
            with open(file_path, 'rb') as audio_file:
                audio_data = audio_file.read()
            
            # Convert to base64
            return self.audio_to_base64(audio_data)
            
        except Exception as e:
            print(f"Error reading audio file: {e}")
            return None
    
    def process_audio_pipeline(self, audio_input, is_file_path: bool = False) -> dict:
        """
        Complete audio processing pipeline: audio -> base64.
        
        Args:
            audio_input: Either audio bytes or file path
            is_file_path: True if audio_input is a file path, False if it's bytes
            
        Returns:
            Dictionary with processing results
        """
        try:
            if is_file_path:
                # Process as file path
                if not isinstance(audio_input, str):
                    return {
                        "success": False,
                        "error": "File path must be a string",
                        "audio_data": None
                    }
                
                audio_base64 = self.file_to_base64(audio_input)
                
                if audio_base64:
                    return {
                        "success": True,
                        "audio_data": audio_base64,
                        "source": "file",
                        "file_path": audio_input,
                        "audio_size_bytes": len(base64.b64decode(audio_base64))
                    }
                else:
                    return {
                        "success": False,
                        "error": "Failed to read or encode audio file",
                        "audio_data": None
                    }
            else:
                # Process as bytes
                if not isinstance(audio_input, bytes):
                    return {
                        "success": False,
                        "error": "Audio input must be bytes when is_file_path=False",
                        "audio_data": None
                    }
                
                audio_base64 = self.audio_to_base64(audio_input)
                
                if audio_base64:
                    return {
                        "success": True,
                        "audio_data": audio_base64,
                        "source": "bytes",
                        "audio_size_bytes": len(audio_input)
                    }
                else:
                    return {
                        "success": False,
                        "error": "Failed to encode audio data",
                        "audio_data": None
                    }
                    
        except Exception as e:
            return {
                "success": False,
                "error": f"Audio processing error: {str(e)}",
                "audio_data": None
            }
    
    def process_text_pipeline(self, text: str, voice: str = None) -> dict:
        """
        Complete text-to-speech pipeline with error handling and metadata.
        
        Args:
            text: Text to convert to speech
            voice: Voice to use (optional)
            
        Returns:
            Dictionary with complete processing results
        """
        try:
            # Validate input
            if not text or not text.strip():
                return {
                    "success": False,
                    "error": "Empty or invalid text provided",
                    "audio_data": None
                }
            
            # Clean and prepare text
            cleaned_text = text.strip()
            
            # Generate audio
            result = self.create_grounding_audio(cleaned_text, voice)
            
            return result
            
        except Exception as e:
            return {
                "success": False,
                "error": f"Pipeline error: {str(e)}",
                "audio_data": None
            }
