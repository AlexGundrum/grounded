# llm_service.py
import os
import random
from typing import List, Dict, Any
from datetime import datetime, timedelta
from openai import OpenAI
from dotenv import load_dotenv
import google.generativeai as genai
load_dotenv()
# Load keys
OpenAI.api_key = os.getenv("OPENAI_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
genai.api_key = os.getenv("GOOGLE_API_KEY")

class llm_communication:
    def __init__(self, message_retention_minutes: int = 30):
        self.client = OpenAI(api_key=OPENAI_API_KEY)
        self.message_history: List[Dict[str, Any]] = []
        self.message_retention_minutes = message_retention_minutes
        self.current_stage = 0
        self.off_topic_count = 0
        self.max_off_topic = 2
        # Grounding exercise prompts
        self.grounding_prompts = [
            # Calm Opener
            "Take a slow breath in... and a gentle breath out. You're safe here. Everything will be okay. Let's move through this together, step by step.",

            # Step 1: See 5 things
            "Let's start with your surroundings. Look around you and notice five things you can see. From your scene, I notice a few objects: [OD pipeline inserts detections here]. What are five things you can see right now?",

            # Step 2: Touch 4 things
            "Now, gently shift your attention to touch. Notice four things you can physically feel—maybe the ground under your feet, the fabric of your clothing, or the surface beneath your hands. What four things can you touch? ",

            # Step 3: Hear 3 things
            "Next, let's listen. Take a moment and notice three sounds around you. They might be loud or very quiet. What three things can you hear right now?",

            # Step 4: Smell 2 things
            "Now, bring your awareness to your sense of smell. Notice two things you can smell in this moment. If nothing stands out, think of two scents you enjoy. What are two things you can smell?",

            # Step 5: Taste 1 thing
            "Finally, let's focus on taste. Notice one thing you can taste right now. Maybe it's a lingering flavor or simply the freshness of your breath. What is one thing you can taste?",

            # Gentle Closure
            "You've just guided yourself through all five steps. Well done. Take a moment to notice how you feel now. Would you like to continue with another round, or pause here?"
        ]
    
    # ------------------------
    # Message Logging System
    # ------------------------
    def log_message(self, user_message: str, llm_response: str, timestamp: float = None) -> None:
        """Log a conversation exchange with timestamp."""
        if timestamp is None:
            timestamp = datetime.now().timestamp()
        
        message_entry = {
            "timestamp": timestamp,
            "datetime": datetime.fromtimestamp(timestamp),
            "user_message": user_message,
            "llm_response": llm_response
        }
        
        self.message_history.append(message_entry)
        self._cleanup_old_messages()
    
    def _cleanup_old_messages(self) -> None:
        """Remove messages older than the retention period."""
        cutoff_time = datetime.now() - timedelta(minutes=self.message_retention_minutes)
        self.message_history = [
            msg for msg in self.message_history 
            if msg["datetime"] > cutoff_time
        ]
    
    def format_conversation_for_context(self, max_messages: int = 5) -> str:
        """Format recent conversation history as context for LLM calls."""
        self._cleanup_old_messages()
        recent_history = self.message_history[-max_messages:] if max_messages > 0 else self.message_history
        
        if not recent_history:
            return ""
        
        context_parts = ["Recent conversation history:"]
        for msg in recent_history:
            context_parts.append(f"User: {msg['user_message']}")
            context_parts.append(f"Assistant: {msg['llm_response']}")
        
        return "\n".join(context_parts)

    # ------------------------
    # OpenAI API call
    # ------------------------
    def openai_prompt(self, prompt: str, model: str = "gpt-4o-mini", include_history: bool = False) -> str:
        messages = [{"role": "system", "content": "You are a calm, grounding therapist helping with anxiety. Respond in two sentences or less."}]
        
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
    # Enhanced Communication Pipeline
    # ------------------------
    def enhanced_message_pipeline(self, user_message: str, timestamp: float = None) -> str:
        """
        Enhanced message processing pipeline with conversation history.
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
        self.log_message(user_message, response, timestamp=timestamp)
        
        return response
    
    # ------------------------
    # Grounding Exercise Pipeline
    # ------------------------
    def process_grounding_exercise(self, user_message: str, timestamp: float = None, od_results: List[str] = None) -> str:
        """Process user input through the grounding exercise pipeline."""
        try:
            
            #
            #
            #
            last_llm_message = "N/A"
            if self.current_stage != 0:
                last_llm_message = self.grounding_prompts[self.current_stage - 1]
            current_step_message = self.grounding_prompts[self.current_stage]
            
            prompt = f"""You are a calm, caring therapist guiding a user through a 5-4-3-2-1 grounding exercise for anxiety.  
Your role is not just to move through steps, but to be a supportive companion who listens patiently and helps the user feel understood.  

Here is the conversation state:

- Last grounding step: "{last_llm_message}"
- User’s reply: "{user_message}"
- Current grounding step prompt: "{current_step_message}"

Rules:
1. If the user clearly followed the instruction (e.g., listed the correct number of things, or engaged with the exercise), respond with "READY:" and THEN gently introduce the **next step’s grounding prompt** in a calm, natural way.  
2. If the user seems distracted, panicked, venting, or going off-topic, respond with "HOLD:" and provide a short, empathetic response that:  
   - Validates their feelings or acknowledges what they said,  
   - Reassures them they are safe talking to you,  
   - And keeps them gently connected to the grounding process without pushing.  
3. Your response after "READY:" or "HOLD:" should be no more than 2 supportive sentences. Keep the tone warm, kind, and human.  
4. Never sound like you are rushing or checking boxes — your priority is to make the user feel heard and cared for, even if they are off-topic.  

Format:  
- Start with either "READY:" or "HOLD:" (nothing else before it).  
- After that, include your message for the user.  
"""
            if self.off_topic_count >= self.max_off_topic:
                self.off_topic_count = 0
                # Gently segue
                prompt = f"""You are a calm and supportive companion.  
The user may have been chatting off-topic or staying in the current step for a while, but now you must gently and smoothly guide them forward without making them feel rushed.  

Here is the conversation state:

- Last assistant message: "{last_llm_message}"
- User’s reply: "{user_message}"
- Current step message: "{current_step_message}"

Rules:
1. Always respond with "READY:" followed by a warm, natural transition that briefly acknowledges what the user said and gently reconnects them to the exercise.  
2. After your transition, immediately provide the {current_step_message}.  
3. The transition should feel kind and conversational, not scripted or mechanical. Use no more than 2 short sentences before moving into the step.  
4. Your priority is to sound supportive and patient — like a friend who cares — while still keeping the grounding exercise moving forward.  

Format:  
- Start with "READY:" (nothing else before it).  
- After that, include your gentle transition + the {current_step_message}.  
"""
                
            
            # Safety clamp on stage index
            if self.current_stage < 0:
                self.current_stage = 0
            elif self.current_stage >= len(self.grounding_prompts):
                self.current_stage = len(self.grounding_prompts) - 1
            
            base_prompt = self.grounding_prompts[self.current_stage]

            # --- Stage Logic ---
            if self.current_stage == 0:  # Calm opener
                #FIXME make intro logic here alex
                response = self._generate_grounding_response(base_prompt, user_message)
                self._advance_stage()

            elif self.current_stage == 1:  # Visual step with OD pipeline
                # Use passed OD results or fallback to mock data
                detected_objects = od_results if od_results else self._get_scene_objects()
                #FIXME make OD be joined
                if detected_objects:
                    prompt += "when prompting the user, mention the objects that are in the scene. The objects are: " + ", ".join(detected_objects) + ". MAKE SURE TO SAY SOMETHING LIKE: from your scene I see ___ and then incorporate it into the way you are going to guide them through the grounding technique."
                #response = self._generate_grounding_response(base_prompt, user_message)
                response = self.openai_prompt(prompt=prompt)
                self._advance_stage()

            elif 2 <= self.current_stage <= 5:  # Touch, Hear, Smell, Taste
                #response = self._generate_grounding_response(base_prompt, user_message)
                response = self.openai_prompt(prompt=prompt)
                self._advance_stage()

            elif self.current_stage == 6:  # Closure
                #response = self._generate_grounding_response(base_prompt, user_message)
                response = self.openai_prompt(prompt=prompt)
                if any(word in user_message.lower() for word in ["continue", "again", "more", "another", "repeat"]):
                    self.reset_exercise()
                    response += " Let's start fresh with another grounding exercise."

            else:
                response = "I'm here to help you through this grounding exercise. Let's take it step by step."


            if response.startswith("HOLD:"):
                response = response[5:]
                self.off_topic_count += 1
                
            if response.startswith("READY:"):
                response = response[6:]
                self.off_topic_count = 0
            
            # Log interaction
            self.log_message(user_message, response, timestamp=timestamp)
            return response
        
        except Exception as e:
            print(f"Error in grounding exercise pipeline: {e}")
            return "I'm here to help you through this. Let's take a gentle breath together and try again. You're doing great."

    def _generate_grounding_response(self, base_prompt: str, user_message: str) -> str:
        """Generate a grounding response using the base prompt + user input."""
        if not user_message.strip():
            # Just use the base prompt if no user input
            return self.openai_prompt(base_prompt, include_history=True)

        # Short acknowledgment to avoid repetition
        ack_templates = [
            f"Thank you for sharing that. ",
            f"I hear you. ",
            f"That's a good observation. ",
            f"Noted. ",
            f"Great awareness. "
        ]
        ack = random.choice(ack_templates)

        # Combine acknowledgment with grounding step
        prompt = f"{base_prompt}\n\nThe user said: '{user_message}'. {ack}Guide them according to the grounding step."
        return self.openai_prompt(prompt, include_history=True)

    def _advance_stage(self):
        """Advance to the next grounding stage, clamping to closure."""
        self.current_stage += 1
        if self.current_stage >= len(self.grounding_prompts):
            self.current_stage = len(self.grounding_prompts) - 1

    def reset_exercise(self):
        """Reset to the opener stage (0)."""
        self.current_stage = 0

    def _get_scene_objects(self) -> List[str]:
        """Fallback method for when no OD results are provided."""
        return ["johnson your friend", "book", "chair"]  # Mock data for testing

    def get_current_grounding_step(self) -> int:
        """Get the current grounding exercise step."""
        return self.current_stage

    def get_grounding_step_description(self) -> str:
        """Get description of current grounding step."""
        if 0 <= self.current_stage < len(self.grounding_prompts):
            return self.grounding_prompts[self.current_stage]
        return "Grounding exercise complete."