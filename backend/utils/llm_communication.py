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
genai.api_key = os.getenv("GEMINI_API_KEY")

class llm_communication:
    def __init__(self, message_retention_minutes: int = 30):
        self.client = OpenAI(api_key=OPENAI_API_KEY)
        self.message_history: List[Dict[str, Any]] = []
        self.message_retention_minutes = message_retention_minutes
        self.current_stage = 0
        self.off_topic_count = 0
        self.max_off_topic = 2

        self.current_procedure = "grounding" #grounding, breathing, videos
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
    # Gemini API call (NEW FUNCTION)
    # ------------------------
    def gemini_prompt(self, prompt: str, model: str = "gemini-2.5-flash", include_history: bool = False) -> str:
        """
        Query the Gemini API for a response.
        Uses the GOOGLE_API_KEY loaded during initialization.
        """
        # Include conversation history if requested
        if include_history:
            context = self.format_conversation_for_context()
            if context:
                # Prepend the context to the prompt
                prompt = f"{context}\n\n{prompt}"
        
        # Add system instruction to the prompt
        system_instruction = "You are a calm, grounding therapist helping with anxiety. Respond in two sentences or less."
        full_prompt = f"{system_instruction}\n\n{prompt}"
        
        try:
            # Call the Gemini API using the correct syntax
            response = genai.GenerativeModel(model).generate_content(full_prompt)
            return response.text
        
        except Exception as e:
            print(f"Gemini API Error: {e}")
            return "I apologize, but I couldn't connect to the AI right now. Let's take a slow breath together."

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
        # response = self.openai_prompt(enhanced_prompt, include_history=True)
        response = self.gemini_prompt(enhanced_prompt, include_history=True)
        
        # Log the conversation exchange
        self.log_message(user_message, response, timestamp=timestamp)
        
        return response

    # ------------------------
    # Grounding Exercise Pipeline
    # ------------------------
    def process_grounding_exercise(self, user_message: str, timestamp: float = None, od_results: List[str] = None,  justSwitchedIntoThis = False) -> str:
        """Process user input through the grounding exercise pipeline."""
        if justSwitchedIntoThis:
            self.current_procedure = 0
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
            
            #base_prompt = self.grounding_prompts[self.current_stage]

            # --- Stage Logic ---
            if self.current_stage == 0:  # Calm opener
                #FIXME make intro logic here alex
                #Take a slow breath in... and a gentle breath out. You're safe here. Everything will be okay. Let's move through this together, step by step.
                response = self._generate_grounding_response(prompt, user_message)
                self._advance_stage()

            elif self.current_stage == 1:  # Visual step with OD pipeline
                # Use passed OD results or fallback to mock data
                detected_objects = od_results if od_results else self._get_scene_objects()
                
                if detected_objects:
                    prompt += "when prompting the user, mention the objects that are in the scene. The objects are: " + ", ".join(detected_objects) + ". MAKE SURE TO SAY SOMETHING LIKE: from your scene I see ___ and then incorporate it into the way you are going to guide them through the grounding technique."
                #response = self._generate_grounding_response(base_prompt, user_message)
                # response = self.openai_prompt(prompt=prompt)
                response = self.gemini_prompt(prompt)
                self._advance_stage()

            elif 2 <= self.current_stage <= 5:  # Touch, Hear, Smell, Taste
                # Use passed OD results or fallback to mock data
                detected_objects = od_results if od_results else self._get_scene_objects()
                
                #response = self._generate_grounding_response(base_prompt, user_message)
                #fixme FIXME if this ends up being dumb then delete FIXME true hasn't been tested
                if detected_objects:
                    prompt += "when prompting the user, mention the objects that are in the scene. The objects are: " + ", ".join(detected_objects) + ". MAKE SURE TO SAY SOMETHING IF ANY OF THESE OBJECTS RELATE TO THE SENSE YOU ARE PRESCRIBING THEM TO FOCUS ON IN THIS GROUNDING TECHNIQUE: from your scene I see ___ and then incorporate it into the way you are going to guide them through the grounding technique."
                
                # response = self.openai_prompt(prompt=prompt)
                response = self.gemini_prompt(prompt)
                self._advance_stage()

            elif self.current_stage == 6:  # Closure
                #response = self._generate_grounding_response(base_prompt, user_message)
                # response = self.openai_prompt(prompt=prompt)
                response = self.gemini_prompt(prompt)
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
                self._advance_stage()
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
            # return self.openai_prompt(base_prompt, include_history=True)
            return self.gemini_prompt(base_prompt, include_history=True)

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
        # return self.openai_prompt(prompt, include_history=True)
        return self.gemini_prompt(prompt, include_history=True)

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

    def breathing_procedure(self, user_message, timestamp: float = None, justSwitchedIntoThis: bool = False):
        """Guide the user through a structured breathing exercise."""
        try:
            if justSwitchedIntoThis:
                response = "FIXME CHANGING TO BREATHING Let's try a simple breathing exercise together. We'll go slowly—inhale, hold, and exhale with me."
                #FIXME add stat into here...
                self.current_stage = 0
                self.log_message(user_message, response, timestamp)
                return response

            breathing_prompts = [
                "Breathe in gently through your nose for a slow count of 4.",
                "Now hold your breath for a count of 4.",
                "Exhale slowly through your mouth for a count of 6.",
                "Pause for a moment and notice the calm settling in your body.",
                "Let's repeat this cycle together if you’d like."
            ]

            if self.current_stage < 0:
                self.current_stage = 0
            elif self.current_stage >= len(breathing_prompts):
                self.current_stage = len(breathing_prompts) - 1

            current_step_message = breathing_prompts[self.current_stage]

            # Simple acknowledgment + step progression
            prompt = f"""
You are a calm, supportive therapist guiding a user through a breathing exercise for anxiety relief.

User said: "{user_message}"
Current step: "{current_step_message}"

Rules:
1. Keep your response under 2 sentences.
2. If the user is following along, gently move to the next step with reassurance.
3. If the user is panicked, off-topic, or needs patience, pause here and reassure them instead of pushing forward.
            """

            # response = self.openai_prompt(prompt=prompt, include_history=True)
            response = self.gemini_prompt(prompt, include_history=True)

            # Advance breathing stage unless user seems to want to pause
            if any(word in user_message.lower() for word in ["stop", "wait", "hold", "pause"]):
                pass  # stay on current step
            else:
                self.current_stage += 1
                if self.current_stage >= len(breathing_prompts):
                    self.current_stage = len(breathing_prompts) - 1

            self.log_message(user_message, response, timestamp=timestamp)
            return response

        except Exception as e:
            print(f"Error in breathing procedure: {e}")
            return "Let’s take a calm breath together and try again. You’re doing great."



    def video_procedure(self, user_message, timestamp: float = None, justSwitchedIntoThis: bool = False):
        """Guide the user through a soothing video suggestion procedure."""
        try:
            soothing_videos = [
                "a quiet forest stream flowing gently",
                "a calming ocean wave video",
                "a soft rainfall on leaves",
                "a fireplace crackling warmly"
            ]

            if justSwitchedIntoThis:
                chosen_video = random.choice(soothing_videos)
                response = f"FIXME CHANGING TO VIDEO I've found something soothing for you—imagine watching {chosen_video}. Let’s let this moment calm your mind."
                self.log_message(user_message, response, timestamp)
                return response

            # Prompt the LLM to keep conversation supportive while referencing video soothing
            prompt = f"""
You are a calming companion. The user is in the 'video' procedure where we play or describe soothing videos.

User said: "{user_message}"

Rules:
1. Respond in under 2 supportive sentences.
2. If the user seems ready, describe a calming video scenario (choose from: {', '.join(soothing_videos)}).
3. If the user is distressed or off-topic, acknowledge what they said empathetically and gently redirect to the calming video imagery.
            """
            #fixme FIXME need to coordinate with kori to make sure that we are introducing the video a friend sent not this 
            # response = self.openai_prompt(prompt=prompt, include_history=True)
            response = self.gemini_prompt(prompt, include_history=True)
            self.log_message(user_message, response, timestamp=timestamp)
            return response

        except Exception as e:
            print(f"Error in video procedure: {e}")
            return "Let’s bring up a calming scene together—imagine gentle waves on a shore as we reset."



    def check_if_user_wants_switch_procedure(self, user_message: str):
        """
        Returns [bool, str] where:
        - bool indicates if the user wants to switch
        - str indicates which procedure to switch to ("breathing", "video", "grounding")
        """
        user_message = user_message.lower()

        # check breathing
        if "anchor" in user_message and any(word in user_message for word in ["breath", "breathe", "breathing", "hyperventilating", "inhale", "exhale", "lungs", "can’t breathe", "hard to breathe", "catch my breath", "air", "oxygen"]):
            return [(self.current_procedure != "breathing"), "breathing"]

        # check video
        if "anchor" in user_message and any(word in user_message for word in ["video"]):
            return [(self.current_procedure != "video"), "video"]

        # check grounding
        if "anchor" in user_message and any(word in user_message for word in ["grounding", "ground", "focus", "present", "panic", "calm down"]):
            return [(self.current_procedure != "grounding"), "grounding"]

        # default: no switch
        return [False, ""]

    

    def starting_point(self, user_message: str, timestamp: float = None, od_results: List[str] = None):
        #func that is called from endpoint, we then direct data toward whatever procedure we're currently in
        wants_to_switch, switch_location = self.check_if_user_wants_switch_procedure(user_message)
        if wants_to_switch:
            for i in range(10):
                print(f"WE WANNA SWITCH TO {switch_location}")
            self.current_procedure = switch_location
        
        if self.current_procedure == "breathing":
            return self.breathing_procedure(user_message, timestamp, justSwitchedIntoThis=wants_to_switch)
        elif self.current_procedure == "video":
            return self.video_procedure(user_message, timestamp, justSwitchedIntoThis=wants_to_switch)
        else:
            return self.process_grounding_exercise(user_message, timestamp, od_results, justSwitchedIntoThis=wants_to_switch)
            #default is grounding procedure