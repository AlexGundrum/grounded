from fastapi import FastAPI

app = FastAPI()

import os
import google.generativeai as genai

genai.api_key = os.getenv("GOOGLE_API_KEY")
our_model = "gemini-2.5-flash"
@app.post("/ask_gemAI")
def ask_gemini(user_input: str, model: str = our_model) -> str:
   
    response = genai.models.generate_content(
        model=model,
        contents=user_input
    )
    return {"response" , response.text }

