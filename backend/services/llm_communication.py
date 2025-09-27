from fastapi import FastAPI


import os
import google.generativeai as genai

genai.api_key = os.getenv("GOOGLE_API_KEY")
our_model = "gemini-2.5-flash"

def ask_gemini(prompt: str, model: str = our_model) -> str:         # WILL NEED ANOTHER FUNCTION THAT GENERATES THE PROMPT THAT WE PASS HERE
   
    response = genai.models.generate_content(
        model=model,
        contents=prompt
    )
    return {"response" , response.text }

