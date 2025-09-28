# Anchor

Anchor is an AI-powered companion that helps guide users through panic attacks in real time. It provides grounding exercises, visualized breathing techniques, and personalized video messages from loved ones. By integrating computer vision and conversational AI, Anchor adapts to the situation and delivers the right support when it’s needed most.

---

## Inspiration
Our team has a history of panic and anxiety attacks. While stigmas around mental health have improved, the gap between people in need and available resources still exists. During a panic attack, thinking about anything but dying is pretty hard. We wanted an app that could help relieve this by doing some of the heavy lifting and critical thinking for the user.

---

## What it does
- Guides users through panic attacks with **grounding exercises**.  
- Provides **visualized breathing techniques** to help regulate stress.  
- Plays **personalized video messages** from loved ones for comfort.  
- Uses **computer vision + conversational AI** to adapt support in real time.  

---

## How we built it
- **Backend:** FastAPI handling computer vision, user data, and Gemini API prompting.  
- **Frontend:** Swift/SwiftUI iOS app for seamless interaction.  
- **Integration:** Real-time communication between backend AI services and the iOS client, enabling responsive and adaptive support.  

---

## Challenges we ran into
- Running computer vision locally on the iPhone/camera.  
- Latency in communication between front-end and backend services.  
- Unfamiliarity with Apple’s ARKit slowed development.  
- Making text-to-speech (TTS) and speech-to-text (STT) sound natural and conversational.  

---

## Accomplishments that we're proud of
- Building a sleek, realistic iOS integration and UI.  
- Tackling a problem deeply relevant to our team’s own experiences with mental health.  
- Successfully leveraging computer vision to strengthen AI prompting.  

---

## What we learned
We learned how to design for accessibility and emotional sensitivity in high-stress situations. We also gained hands-on experience combining iOS AR development, backend APIs, and computer vision pipelines into a real-time system. Beyond the technical challenges, we learned how important it is to align design decisions with empathy and user trust.

---

## What's next for Anchor
Our next step is implementation with **smart glasses**, enabling hands-free, immersive support that feels natural in the moment. With wearable integration, Anchor can provide even more seamless, discreet, and personalized assistance.
