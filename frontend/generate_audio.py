#!/usr/bin/env python3
"""
Generate high-quality audio files for Grounded app using OpenAI TTS API
Run this script to create the critical audio files for your demo
"""

import os
import requests
import json
from pathlib import Path

# Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "YOUR_OPENAI_API_KEY_HERE")
OPENAI_TTS_URL = "https://api.openai.com/v1/audio/speech"

# Audio files to generate
CRITICAL_PHRASES = {
    "intro_calm.mp3": "Hello. I am here for you. Take a slow, deep breath. We are starting the grounding protocol now.",
    "end_calm.mp3": "You're doing great. The crisis intervention is complete. Take care of yourself.",
    "fallback_calm.mp3": "Take a deep breath. Look around you and find five things you can see. Name them out loud. You're safe, and this feeling will pass."
}

# Voice options ()
VOICE_OPTIONS = [
    "alloy",    # Clear, neutral
    "echo",     # Warm, friendly
    "fable",    # Expressive, storytelling
    "onyx",     # Deep, authoritative
    "nova",     # Bright, energetic
    "shimmer"   # Soft, gentle
]

def generate_audio_file(text, filename, voice="nova"):
    """Generate audio file using OpenAI TTS API"""
    
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": "tts-1-hd",  # High quality model
        "input": text,
        "voice": voice,
        "response_format": "mp3",
        "speed": 0.8  # Slightly slower for calming effect
    }
    
    print(f"🎤 Generating: {filename}")
    print(f"📝 Text: '{text}'")
    print(f"🎵 Voice: {voice}")
    
    try:
        response = requests.post(OPENAI_TTS_URL, headers=headers, json=data)
        
        if response.status_code == 200:
            # Save the audio file
            audio_path = Path("Grounded") / "AudioFiles" / filename
            audio_path.parent.mkdir(exist_ok=True)
            
            with open(audio_path, 'wb') as f:
                f.write(response.content)
            
            print(f"✅ Successfully saved: {audio_path}")
            print(f"📊 File size: {len(response.content)} bytes")
            return True
            
        else:
            print(f"❌ Error {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

def main():
    """Generate all critical audio files"""
    
    print("🎤 Grounded Audio Generator")
    print("=" * 50)
    
    # Check if API key is set
    if OPENAI_API_KEY == "YOUR_OPENAI_API_KEY_HERE":
        print("❌ Please set your OpenAI API key in the script!")
        print("Edit the OPENAI_API_KEY variable with your actual key.")
        return
    
    print(f"🔑 Using API key: {OPENAI_API_KEY[:10]}...")
    print()
    
    # Generate each critical phrase
    success_count = 0
    total_count = len(CRITICAL_PHRASES)
    
    for filename, text in CRITICAL_PHRASES.items():
        if generate_audio_file(text, filename, voice="nova"):  # Using 'nova' voice
            success_count += 1
        print()
    
    print("=" * 50)
    print(f"🎯 Generated {success_count}/{total_count} audio files")
    
    if success_count == total_count:
        print("✅ All critical audio files generated successfully!")
        print("\n📱 Next steps:")
        print("1. Add these files to your Xcode project")
        print("2. Update CrisisManager.swift to use the audio files")
        print("3. Test the hybrid TTS system")
    else:
        print("❌ Some files failed to generate. Check your API key and network connection.")

if __name__ == "__main__":
    main()
