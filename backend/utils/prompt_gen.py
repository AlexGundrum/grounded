import requests
import time
from openai import OpenAI

# def step_input(obj_list: list, step: int):
#     try:
#         prompt=f""""
#         You are a calm, supportive Grounding Assistant. 
#         Your only task is to guide the user through the 5-4-3-2-1 Grounding Technique. 

#         Input: 
#         - Current step number = {step}
#         - List of detected objects with counts and attributes (e.g., color, size, texture) = {obj_list}

#         Rules: 
#         - Output must be plain text only, ready for text-to-speech. 
#         - Exactly one line of output. 
#         - The line must begin with the step number, followed by a colon and a space. 
#         - The instruction must be short, direct, and correspond to the correct step: 

#         Step 1 → Sight  
#         - “Name 5 things you can see.”  
#         - Variation: “Name 5 red things,” “Name 5 round things,” “Name 5 big things,” etc.  
#         - Prefer attributes present in {obj_list}.  

#         Step 2 → Touch  
#         - “Notice 4 things you can touch.”  
#         - Variation: “Notice 4 smooth surfaces,” “Notice 4 rough textures,” “Notice 4 soft things.”  
#         - Prefer textures or object types from {obj_list}.  

#         Step 3 → Hearing  
#         - “Listen for 3 sounds you can hear.”  
#         - Variation: “Listen for 3 steady sounds,” “Listen for 3 soft noises,” “Listen for 3 nearby sounds.”  
#         - If no CV data applies, use generic sensory phrasing.  

#         Step 4 → Smell  
#         - “Identify 2 things you can smell.”  
#         - Variation: “Identify 2 familiar scents,” “Identify 2 things that might have a smell nearby (like food, plants, or fabric).”  

#         Step 5 → Taste  
#         - “Focus on 1 thing you can taste.”  
#         - Variation: “Focus on 1 lingering taste,” “Focus on 1 drink or snack nearby.”  

#         - No extra sentences, no filler, no introductions or closings.


#         """
#         payload = {
#             "model": "gemma3:latest",
#             "prompt": prompt,
#             "stream": False
#         }
        
#         response = requests.post(
#             f"http://localhost:11434/api/generate",
#             json=payload,
#         )
        
#         result = response.json()
#         return result.get('response', '')
            
#     except Exception as e:
#         print(f"Error: {e}")
#     return None



# def tes_openai(obj_list: list, step: int):
#     client = OpenAI(api_key="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")
#     prompt=f""""
#         You are a calm, supportive Grounding Assistant. 
#         Your only task is to guide the user through the 5-4-3-2-1 Grounding Technique. 

#         Input: 
#         - Current step number = {step}
#         - List of detected objects with counts and attributes (e.g., color, size, texture) = {obj_list}

#         Rules: 
#         - Output must be plain text only, ready for text-to-speech. 
#         - Exactly one line of output. 
#         - The line must begin with the step number, followed by a colon and a space. 
#         - The instruction must be short, direct, and correspond to the correct step: 

#         Step 1 → Sight  
#         - “Name 5 things you can see.”  
#         - Variation: “Name 5 red things,” “Name 5 round things,” “Name 5 big things,” etc.  
#         - Prefer attributes present in {obj_list}.  

#         Step 2 → Touch  
#         - Prefer textures or object types from {obj_list}.  
#         - “Notice 4 things you can touch.”  
#         - Variation: “Notice 4 smooth surfaces,” “Notice 4 rough textures,” “Notice 4 soft things.”  

#         Step 3 → Hearing  
#         - “Listen for 3 sounds you can hear.”  
#         - Variation: “Listen for 3 steady sounds,” “Listen for 3 soft noises,” “Listen for 3 nearby sounds.”  
#         - If no CV data applies, use generic sensory phrasing.  

#         Step 4 → Smell  
#         - “Identify 2 things you can smell.”  
#         - Variation: “Identify 2 familiar scents,” “Identify 2 things that might have a smell nearby (like food, plants, or fabric).”  

#         Step 5 → Taste  
#         - “Focus on 1 thing you can taste.”  
#         - Variation: “Focus on 1 lingering taste,” “Focus on 1 drink or snack nearby.”  

#         - No extra sentences, no filler, no introductions or closings.


#         """
#     response = client.responses.create(
#         model="gpt-5",
#         input=prompt
#     )

#     return(response.output_text)


import random 
import requests
import time
from openai import OpenAI

def create_prompt(obj_list: list, step: int):
    client = OpenAI(api_key="placeholder")
    flat_props = [prop for _, _, props in obj_list for prop in props]
    chosen_attr = random.choice(flat_props) if flat_props else None

    setting = (
        "You are a calm, supportive Grounding Assistant. "
        "Your only task is to guide the user through one of the step of the 5-4-3-2-1 Grounding Technique. "
        "Output must be one short instruction, plain text only, beginning with the step number and a colon."
    )

    if step == 1:
        # Sight
        base = "1: Name 5 things you can see."
        case = f"1: Name 5 {chosen_attr} things you can see." if chosen_attr else base

    elif step == 2:
        # Touch
        base = "2: Notice 4 things you can touch."
        case = f"2: Notice 4 {chosen_attr} surfaces or objects you can touch." if chosen_attr else base

    elif step == 3:
        # Hearing
        base = "3: Listen for 3 sounds you can hear."
        case = base  # usually generic

    elif step == 4:
        # Smell
        base = "4: Identify 2 things you can smell."
        if chosen_attr in ["food", "plant", "fabric"]:
            case = f"4: Identify 2 {chosen_attr} scents nearby."
        else:
            case = base

    elif step == 5:
        # Taste
        base = "5: Focus on 1 thing you can taste."
        if chosen_attr in ["food", "drink", "snack"]:
            case = f"5: Focus on 1 {chosen_attr} you can taste."
        else:
            case = base

    else:
        raise ValueError("Step must be between 1 and 5.")

    prompt = f"{setting}\n\n{case}"

    response = client.responses.create(
        model="gpt-5",  # swap to "gemma-3-4b" when running locally
        input=prompt
    )


    return response.output_text


# st=time.time()
# obj_list = [
#     ["apple", 3, ["red", "round", "smooth"]],
#     ["carpet", 1, ["rough", "soft"]],
#     ["lamp", 1, ["bright", "tall"]]
# ]
# print(prompt_gen(obj_list,4))
# print(time.time()-st)