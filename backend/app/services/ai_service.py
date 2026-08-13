import os
import json
import google.generativeai as genai

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

def analyze_grievance(text: str) -> dict:
    fallback = {
        "category": "Other",
        "issue_type": "General Complaint",
        "priority": "Medium",
        "department": "General Administration",
        "summary": text[:100] + "..." if len(text) > 100 else text,
        "ai_status": "fallback"
    }

    if not GEMINI_API_KEY:
        return fallback

    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        prompt = f"""You are an AI government grievance classification engine. Analyze the citizen's complaint.
Determine: 1) category 2) issue_type 3) priority 4) department 5) summary.
Return ONLY valid JSON with keys: category, issue_type, priority, department, summary.
Do not include markdown or any explanation outside the JSON.
Priority must be exactly one of: Low, Medium, High, Critical.
Choose the department most appropriate for resolving the complaint from a standard civic-department list.

Complaint:
"{text}"
"""
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # Remove markdown if the model hallucinates it
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.startswith("```"):
            response_text = response_text[3:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
            
        data = json.loads(response_text)
        
        # Validate priority
        if data.get("priority") not in ["Low", "Medium", "High", "Critical"]:
            data["priority"] = "Medium"
            
        # Add a flag to say AI was used successfully
        data["ai_status"] = "success"
        
        return data

    except Exception as e:
        print(f"AI Analysis Failed: {e}")
        return fallback
