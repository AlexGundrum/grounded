#!/usr/bin/env python3
"""
Quick test script to verify your OpenAI API key works
Run this to test your API key before using it in the iOS app
"""

import requests
import json

# Replace with your actual API key
API_KEY = "YOUR_OPENAI_API_KEY_HERE"

def test_openai_tts():
    """Test OpenAI TTS API"""
    
    if API_KEY == "YOUR_OPENAI_API_KEY_HERE":
        print("❌ Please set your OpenAI API key in the script!")
        return False
    
    url = "https://api.openai.com/v1/audio/speech"
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": "tts-1-hd",
        "input": "Hello, this is a test of the OpenAI TTS API.",
        "voice": "nova",
        "response_format": "mp3",
        "speed": 0.8
    }
    
    print("🧪 Testing OpenAI TTS API...")
    print(f"🔑 API Key: {API_KEY[:10]}...")
    print(f"🌐 URL: {url}")
    print(f"📝 Text: {data['input']}")
    print(f"🎵 Voice: {data['voice']}")
    
    try:
        response = requests.post(url, headers=headers, json=data)
        
        print(f"📡 HTTP Status: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ API call successful!")
            print(f"📊 Received {len(response.content)} bytes of audio data")
            
            # Save test audio file
            with open("test_audio.mp3", "wb") as f:
                f.write(response.content)
            print("💾 Saved test audio to: test_audio.mp3")
            print("🎧 Play this file to hear the OpenAI TTS quality!")
            
            return True
            
        else:
            print(f"❌ API call failed with status {response.status_code}")
            print(f"📝 Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

if __name__ == "__main__":
    success = test_openai_tts()
    
    if success:
        print("\n🎉 Your OpenAI API key is working!")
        print("📱 You can now use it in your iOS app.")
    else:
        print("\n❌ API key test failed.")
        print("🔧 Please check your API key and try again.")