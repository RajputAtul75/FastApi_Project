"""AI classification service using Google Gemini API."""
import os
import json
import re
from typing import Optional


FALLBACK_RESULT = {
    "category": "Other",
    "issue_type": "General Complaint",
    "priority": "Medium",
    "department": "General Administration",
}

VALID_PRIORITIES = {"Low", "Medium", "High", "Critical"}

SYSTEM_INSTRUCTION = (
    "You are an AI government grievance classification engine. "
    "Analyze the citizen's complaint. Determine: "
    "1) category 2) issue_type 3) priority 4) department 5) summary. "
    "Return ONLY valid JSON with keys category, issue_type, priority, department, summary. "
    "Do not include markdown or any explanation outside the JSON. "
    "priority must be exactly one of: Low, Medium, High, Critical. "
    "Choose the department most appropriate for resolving the complaint from a standard civic-department list."
)


def _parse_gemini_response(text: str) -> Optional[dict]:
    """Parse Gemini response, stripping markdown fences if present."""
    text = text.strip()
    # Remove markdown code fences
    text = re.sub(r'^```(?:json)?\s*', '', text)
    text = re.sub(r'\s*```$', '', text)
    text = text.strip()

    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return None

    # Validate required keys
    required = {"category", "issue_type", "priority", "department", "summary"}
    if not required.issubset(data.keys()):
        return None

    # Validate priority
    if data["priority"] not in VALID_PRIORITIES:
        data["priority"] = "Medium"

    return data


def analyze_grievance(text: str) -> tuple[dict, str]:
    """
    Analyze grievance text using Gemini AI.
    Returns (classification_dict, ai_status) where ai_status is 'success' or 'fallback'.
    """
    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        print("[!] GEMINI_API_KEY not set -- using fallback classification.")
        return _make_fallback(text), "fallback"

    try:
        from google import genai

        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=f"Classify this citizen grievance:\n\n{text}",
            config=genai.types.GenerateContentConfig(
                system_instruction=SYSTEM_INSTRUCTION,
                temperature=0.2,
            ),
        )

        result = _parse_gemini_response(response.text)
        if result is None:
            print(f"[!] Gemini returned unparseable response: {response.text[:200]}")
            return _make_fallback(text), "fallback"

        return result, "success"

    except Exception as e:
        print(f"[!] Gemini API error: {e}")
        return _make_fallback(text), "fallback"


def _make_fallback(text: str) -> dict:
    """Create fallback classification when AI is unavailable."""
    summary = text[:150].strip()
    if len(text) > 150:
        summary += "..."
    return {
        **FALLBACK_RESULT,
        "summary": summary,
    }
