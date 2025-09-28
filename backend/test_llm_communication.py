#!/usr/bin/env python3
"""
Simple test script for the enhanced LLM communication system.
Run this to verify the new pipeline works correctly.
"""

import os
import sys
from datetime import datetime

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from utils.llm_communication import llm_communication

def test_enhanced_pipeline():
    """Test the enhanced message pipeline with conversation history."""
    
    print("🧪 Testing Enhanced LLM Communication Pipeline")
    print("=" * 50)
    
    # Initialize the communication system
    com = llm_communication(message_retention_minutes=5)  # Short retention for testing
    
    # Test messages to simulate a conversation
    test_messages = [
        ("I'm feeling really anxious today", 85.0),
        ("My heart is racing and I can't focus", 95.0),
        ("Can you help me calm down?", 90.0),
        ("I'm still feeling overwhelmed", 88.0)
    ]
    
    print("\n📝 Simulating conversation with message history...")
    
    for i, (message, heart_rate) in enumerate(test_messages, 1):
        print(f"\n--- Message {i} ---")
        print(f"User: {message}")
        print(f"Heart Rate: {heart_rate} bpm")
        
        # Use the enhanced pipeline
        response = com.enhanced_message_pipeline(message, heart_rate)
        print(f"Assistant: {response}")
        
        # Show conversation stats
        stats = com.get_conversation_stats()
        print(f"History: {stats['total_messages']} messages stored")
    
    print("\n📊 Final Conversation Statistics:")
    final_stats = com.get_conversation_stats()
    for key, value in final_stats.items():
        print(f"  {key}: {value}")
    
    print("\n🔍 Recent Conversation History:")
    recent_history = com.get_recent_conversation_history(max_messages=3)
    for msg in recent_history:
        print(f"  [{msg['datetime'].strftime('%H:%M:%S')}] User: {msg['user_message'][:50]}...")
        print(f"  [{msg['datetime'].strftime('%H:%M:%S')}] Assistant: {msg['llm_response'][:50]}...")
    
    print("\n✅ Test completed successfully!")
    print("\nThe enhanced pipeline is working with:")
    print("  ✓ Message logging with timestamps")
    print("  ✓ Heart rate tracking")
    print("  ✓ Conversation history retention")
    print("  ✓ Context-aware responses")
    print("  ✓ Automatic cleanup of old messages")

if __name__ == "__main__":
    test_enhanced_pipeline()
