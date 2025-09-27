# llm_service.py
import os
from typing import List, Dict, Any
from datetime import datetime, timedelta
from openai import OpenAI

import google.generativeai as genai

# Load keys
OpenAI.api_key = os.getenv("OPENAI_API_KEY")
genai.api_key = os.getenv("GOOGLE_API_KEY")

class llm_communication:
    def __init__(self, message_retention_minutes: int = 30):
        self.previous_messages: List[str] = []
        self.gemini_model = "gemini-2.5-flash"
        self.client = OpenAI(api_key=OpenAI.api_key)
        
        # New message logging system
        self.message_history: List[Dict[str, Any]] = []
        self.message_retention_minutes = message_retention_minutes
    
    # ------------------------
    # Message Logging System
    # ------------------------
    def log_message(self, user_message: str, llm_response: str, heart_rate: float = None, timestamp: float = None) -> None:
        """
        Log a conversation exchange with timestamp and metadata.
        """
        if timestamp is None:
            timestamp = datetime.now().timestamp()
        
        message_entry = {
            "timestamp": timestamp,
            "datetime": datetime.fromtimestamp(timestamp),
            "user_message": user_message,
            "llm_response": llm_response,
            "heart_rate": heart_rate
        }
        
        self.message_history.append(message_entry)
        self._cleanup_old_messages()
    
    def _cleanup_old_messages(self) -> None:
        """
        Remove messages older than the retention period.
        """
        cutoff_time = datetime.now() - timedelta(minutes=self.message_retention_minutes)
        self.message_history = [
            msg for msg in self.message_history 
            if msg["datetime"] > cutoff_time
        ]
    
    def get_recent_conversation_history(self, max_messages: int = 10) -> List[Dict[str, Any]]:
        """
        Get the most recent conversation history within the retention period.
        """
        self._cleanup_old_messages()
        return self.message_history[-max_messages:] if max_messages > 0 else self.message_history
    
    def format_conversation_for_context(self, max_messages: int = 5) -> str:
        """
        Format recent conversation history as context for LLM calls.
        """
        recent_history = self.get_recent_conversation_history(max_messages)
        
        if not recent_history:
            return ""
        
        context_parts = ["Recent conversation history:"]
        for msg in recent_history:
            hr_info = f" (HR: {msg['heart_rate']})" if msg.get('heart_rate') else ""
            context_parts.append(f"User: {msg['user_message']}{hr_info}")
            context_parts.append(f"Assistant: {msg['llm_response']}")
        
        return "\n".join(context_parts)
    # ------------------------
    # Gemini API call
    # ------------------------
    def ask_gemini(self, prompt: str) -> str:
        response = genai.models.generate_content(
            model=self.gemini_model,
            contents=prompt
        )
        return response.text

    # ------------------------
    # OpenAI API call
    # ------------------------
    def openai_prompt(self, prompt: str, model: str = "gpt-4o-mini", include_history: bool = False) -> str:
        messages = [{"role": "system", "content": "You are a calm, grounding therapist helping with anxiety."}]
        
        # Include conversation history if requested
        if include_history:
            context = self.format_conversation_for_context()
            if context:
                messages.append({"role": "system", "content": f"Context: {context}"})
        
        messages.append({"role": "user", "content": prompt})
        
        response = self.client.chat.completions.create(
            model=model,
            messages=messages
        )
        return response.choices[0].message.content

    # ------------------------
    # Basic talking test
    # ------------------------
    def basic_talking_test(self, message: str) -> str:
        ADAPTIVE_COACH_PROMPT = f"""
        Message received: {message}
        Respond in a calm, grounding way for anxiety. Respond in two sentences or less
        """
        response = self.openai_prompt(ADAPTIVE_COACH_PROMPT)
        return response

    # ------------------------
    # Enhanced Communication Pipeline
    # ------------------------
    def enhanced_message_pipeline(self, user_message: str, heart_rate: float = None, timestamp: float = None) -> str:
        """
        New comprehensive message processing pipeline with conversation history.
        This is the main entry point for processing user messages.
        """
        # Get conversation context
        context = self.format_conversation_for_context(max_messages=3)
        
        # Create enhanced prompt with context
        if context:
            enhanced_prompt = f"""
            Context from recent conversation:
            {context}
            
            Current message: {user_message}
            
            Respond in a calm, grounding way for anxiety. Consider the conversation context and respond appropriately. 
            Respond in two sentences or less.
            """
        else:
            enhanced_prompt = f"""
            Message received: {user_message}
            Respond in a calm, grounding way for anxiety. Respond in two sentences or less.
            """
        
        # Generate response with history context
        response = self.openai_prompt(enhanced_prompt, include_history=True)
        
        # Log the conversation exchange
        self.log_message(user_message, response, heart_rate, timestamp)
        
        return response
    
    # ------------------------
    # Legacy Functions (Preserved)
    # ------------------------
    def new_message_protocol(self, user_message: str) -> str:
        """
        Legacy function - now uses the enhanced pipeline internally.
        Maintained for backward compatibility.
        """
        self.previous_messages.append(user_message)
        response = self.enhanced_message_pipeline(user_message)
        return response
    
    # ------------------------
    # Additional Utility Functions
    # ------------------------
    def get_conversation_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the current conversation history.
        """
        self._cleanup_old_messages()
        
        if not self.message_history:
            return {
                "total_messages": 0,
                "retention_period_minutes": self.message_retention_minutes,
                "oldest_message": None,
                "newest_message": None
            }
        
        return {
            "total_messages": len(self.message_history),
            "retention_period_minutes": self.message_retention_minutes,
            "oldest_message": self.message_history[0]["datetime"].isoformat(),
            "newest_message": self.message_history[-1]["datetime"].isoformat()
        }
    
    def clear_conversation_history(self) -> None:
        """
        Clear all conversation history.
        """
        self.message_history.clear()
        self.previous_messages.clear()
    
    def set_retention_period(self, minutes: int) -> None:
        """
        Update the message retention period.
        """
        self.message_retention_minutes = minutes
        self._cleanup_old_messages()
