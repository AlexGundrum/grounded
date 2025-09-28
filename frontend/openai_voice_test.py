#!/usr/bin/env python3
"""
OpenAI Voice Generation Script
Uses the OpenAI TTS API to generate speech with the 'shimmer' voice
"""

import openai
import os
from pathlib import Path

# Set your OpenAI API key
openai.api_key = "YOUR_OPENAI_API_KEY"

def generate_speech(text, voice="shimmer", output_file="output.mp3"):
    """
    Generate speech using OpenAI TTS API
    
    Args:
        text (str): Text to convert to speech
        voice (str): Voice to use (alloy, echo, fable, onyx, nova, shimmer)
        output_file (str): Output filename
    """
    try:
        print(f"🎤 Generating speech with '{voice}' voice...")
        print(f"📝 Text: '{text}'")
        
        # Call OpenAI TTS API
        response = openai.audio.speech.create(
            model="tts-1",  # or "tts-1-hd" for higher quality
            voice=voice,
            input=text
        )
        
        # Save the audio file
        output_path = Path(output_file)
        response.stream_to_file(output_path)
        
        print(f"✅ Speech generated successfully!")
        print(f"📁 Saved to: {output_path.absolute()}")
        print(f"🎵 File size: {output_path.stat().st_size} bytes")
        
        return output_path
        
    except Exception as e:
        print(f"❌ Error generating speech: {e}")
        return None

def main():
    """Main function"""
    print("🌊 OpenAI Voice Generation Test")
    print("=" * 40)
    
    # The text you want to convert to speech
    text = "You've come a long way in this session. Trust yourself - you know what you need. I'll be here whenever you need to anchor again."
    
    # Generate speech with shimmer voice
    output_file = generate_speech(
        text=text,
        voice="shimmer",
        output_file="chair_counting_shimmer.mp3"
    )
    
    if output_file:
        print(f"\n🎉 Success! You can now play '{output_file}' to hear the generated speech.")
        print("\n💡 To play the file:")
        print(f"   - On Mac: open '{output_file}'")
        print(f"   - On Windows: start '{output_file}'")
        print(f"   - On Linux: xdg-open '{output_file}'")
    else:
        print("\n❌ Failed to generate speech. Check your API key and internet connection.")

if __name__ == "__main__":
    main()