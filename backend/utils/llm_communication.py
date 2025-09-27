# llm_service.py
import os
from typing import List
from openai import OpenAI

import google.generativeai as genai

# Load keys
OpenAI.api_key = os.getenv("OPENAI_API_KEY")
genai.api_key = os.getenv("GOOGLE_API_KEY")

class llm_communication:
    def __init__(self):
        self.previous_messages: List[str] = []
        self.gemini_model = "gemini-2.5-flash"
        self.client = OpenAI(api_key=OpenAI.api_key)
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
    def openai_prompt(self, prompt: str, model: str = "gpt-4o-mini") -> str:
        response = self.client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are a calm, grounding therapist helping with anxiety."},
            {"role": "user", "content": prompt}
        ]
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
    # New message protocol
    # ------------------------
    def new_message_protocol(self, user_message: str) -> str:
        """
        Evaluate previous messages and guide user gently.
        """
        #if len(self.previous_messages) > 3:
        #    prompt = "Let's try something different. How are you feeling now?"
        #else:
        #    prompt = f"Gentle reminder: {user_message}"

        self.previous_messages.append(user_message)
        return self.basic_talking_test(user_message)
