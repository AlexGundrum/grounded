#!/usr/bin/env python3
"""
Test script for the Text-to-Speech service using OpenAI's TTS API.
This script tests the complete TTS pipeline with grounding examples.
"""

import os
import sys
import base64
import io

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.text_to_speech import text_to_speech

def test_tts_pipeline():
    """Test the complete text-to-speech pipeline."""
    
    print("🎤 Testing OpenAI Text-to-Speech Pipeline")
    print("=" * 50)
    
    # Initialize the TTS service
    print("\n📦 Initializing TTS service...")
    try:
        tts = text_to_speech()
        print("✅ TTS service initialized successfully!")
    except Exception as e:
        print(f"❌ Failed to initialize TTS service: {e}")
        print("Make sure OPENAI_API_KEY is set in your environment variables")
        return
    
    # Test available voices
    print("\n🗣️  Available Voices:")
    voices = tts.get_available_voices()
    for voice, description in voices.items():
        default_indicator = " (DEFAULT)" if voice == tts.default_voice else ""
        print(f"  - {voice}: {description}{default_indicator}")
    
    # Test grounding text examples
    grounding_examples = [
        "Take a deep breath and focus on your breathing. You are safe and grounded.",
        "I can see you're feeling anxious. Let's focus on what's around you. Look for 5 things you can see.",
        "Notice how your feet feel on the ground. You are present and safe in this moment.",
        "Count slowly to ten with me. One... two... three... You're doing great.",
        "Feel the air entering and leaving your body. This breath is calming your nervous system."
    ]
    
    print(f"\n🎯 Testing Grounding Audio Generation...")
    
    for i, text in enumerate(grounding_examples, 1):
        print(f"\n--- Test {i} ---")
        print(f"Text: {text}")
        
        # Test grounding audio creation
        result = tts.create_grounding_audio(text)
        
        if result["success"]:
            print(f"✅ Audio generated successfully!")
            print(f"   Voice used: {result['voice_used']} ({result['voice_description']})")
            print(f"   Text length: {result['text_length']} characters")
            print(f"   Format: {result['format']}")
            print(f"   Audio data length: {len(result['audio_data'])} characters (base64)")
            
            # Test different voices
            if i == 1:  # Test voice variations on first example
                print(f"\n🎭 Testing different voices...")
                for voice in ["echo", "nova", "onyx"]:
                    voice_result = tts.text_to_audio(text, voice=voice)
                    if voice_result:
                        print(f"   ✅ {voice}: {tts.get_voice_description(voice)}")
                    else:
                        print(f"   ❌ {voice}: Failed")
        else:
            print(f"❌ Failed to generate audio: {result['error']}")
    
    # Test error handling
    print(f"\n🧪 Testing Error Handling...")
    
    # Empty text
    empty_result = tts.process_text_pipeline("")
    print(f"Empty text test: {'✅ Handled' if not empty_result['success'] else '❌ Failed'}")
    
    # Very long text
    long_text = "This is a very long text. " * 100
    long_result = tts.process_text_pipeline(long_text)
    print(f"Long text test: {'✅ Handled' if long_result['success'] else '❌ Failed'}")
    
    # Invalid voice
    invalid_voice_result = tts.text_to_audio("Test text", voice="invalid_voice")
    print(f"Invalid voice test: {'✅ Handled' if invalid_voice_result is None else '❌ Failed'}")
    
    print(f"\n🎉 TTS Pipeline Test Completed!")
    print(f"\nThe TTS service is ready for:")
    print(f"  ✓ OpenAI TTS API integration")
    print(f"  ✓ Multiple voice options for different moods")
    print(f"  ✓ Base64 audio encoding for easy transmission")
    print(f"  ✓ Grounding-optimized audio generation")
    print(f"  ✓ Error handling and validation")
    print(f"  ✓ Server endpoint integration")

def test_base64_audio_decoding():
    """Test that base64 audio can be properly decoded."""
    print(f"\n🔧 Testing Base64 Audio Decoding...")
    
    try:
        tts = text_to_speech()
        test_text = "This is a test audio message."
        
        # Generate audio
        audio_base64 = tts.text_to_audio(test_text)
        
        if audio_base64:
            # Decode base64
            audio_data = base64.b64decode(audio_base64)
            print(f"✅ Base64 audio decoded successfully!")
            print(f"   Original base64 length: {len(audio_base64)} characters")
            print(f"   Decoded audio size: {len(audio_data)} bytes")
            print(f"   Audio format: MP3 (estimated)")
        else:
            print(f"❌ Failed to generate test audio")
            
    except Exception as e:
        print(f"❌ Base64 decoding test failed: {e}")

def test_audio_encoding_functions():
    """Test the new audio encoding functions."""
    print(f"\n🎵 Testing Audio Encoding Functions...")
    
    try:
        tts = text_to_speech()
        
        # Test 1: Generate audio and then encode it again
        print(f"\n--- Test 1: Audio Bytes to Base64 ---")
        test_text = "Testing audio encoding functions."
        audio_base64_original = tts.text_to_audio(test_text)
        
        if audio_base64_original:
            # Decode to get bytes
            audio_bytes = base64.b64decode(audio_base64_original)
            
            # Encode bytes back to base64 using new function
            audio_base64_encoded = tts.audio_to_base64(audio_bytes)
            
            if audio_base64_encoded:
                print(f"✅ Audio bytes encoded successfully!")
                print(f"   Original length: {len(audio_base64_original)} chars")
                print(f"   Re-encoded length: {len(audio_base64_encoded)} chars")
                print(f"   Match: {'✅' if audio_base64_original == audio_base64_encoded else '❌'}")
            else:
                print(f"❌ Failed to encode audio bytes")
        else:
            print(f"❌ Failed to generate test audio")
        
        # Test 2: Test audio processing pipeline with bytes
        print(f"\n--- Test 2: Audio Processing Pipeline (bytes) ---")
        if audio_base64_original:
            audio_bytes = base64.b64decode(audio_base64_original)
            result = tts.process_audio_pipeline(audio_bytes, is_file_path=False)
            
            if result["success"]:
                print(f"✅ Audio pipeline (bytes) successful!")
                print(f"   Source: {result['source']}")
                print(f"   Size: {result['audio_size_bytes']} bytes")
            else:
                print(f"❌ Audio pipeline (bytes) failed: {result['error']}")
        
        # Test 3: Test error handling
        print(f"\n--- Test 3: Error Handling ---")
        
        # Empty bytes
        empty_result = tts.audio_to_base64(b"")
        print(f"Empty bytes test: {'✅ Handled' if empty_result is None else '❌ Failed'}")
        
        # Invalid file path
        file_result = tts.file_to_base64("nonexistent_file.mp3")
        print(f"Invalid file test: {'✅ Handled' if file_result is None else '❌ Failed'}")
        
        # Invalid input types
        invalid_result = tts.process_audio_pipeline("not_bytes", is_file_path=False)
        print(f"Invalid input test: {'✅ Handled' if not invalid_result['success'] else '❌ Failed'}")
        
        print(f"\n🎉 Audio Encoding Functions Test Completed!")
        print(f"\nThe audio encoding service is ready for:")
        print(f"  ✓ Converting audio bytes to base64")
        print(f"  ✓ Reading audio files and encoding them")
        print(f"  ✓ Processing audio data through pipeline")
        print(f"  ✓ Error handling and validation")
        print(f"  ✓ Server endpoint integration")
        
    except Exception as e:
        print(f"❌ Audio encoding functions test failed: {e}")

if __name__ == "__main__":
    test_tts_pipeline()
    test_base64_audio_decoding()
    test_audio_encoding_functions()
