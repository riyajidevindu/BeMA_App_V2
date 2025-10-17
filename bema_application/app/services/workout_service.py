import json
from models.user_health import UserHealthProfile
from models.workout_per_day import WorkoutSummary
from fastapi import APIRouter
from datetime import datetime
import logging
import requests
import os
from dotenv import load_dotenv

load_dotenv()

router = APIRouter()
logger = logging.getLogger(__name__)

NGROK_URL = os.getenv("NGROK_URL")


async def generate_workout_motivation(user_id: str, performance_context: str) -> str:
    """Generate AI motivational feedback for workout performance"""
    try:
        prompt = f"""You are a supportive fitness coach. Based on the user's workout performance, provide a brief, motivational message (2-3 sentences max).
        
Performance: {performance_context}

Provide encouragement, celebrate achievements, and offer constructive tips for improvement. Be positive and energetic!"""

        payload = {
            "model": "qwen3:8b",
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.7}
        }
        
        res = requests.post(
            f"{NGROK_URL}/api/generate",
            headers={"Content-Type": "application/json"},
            json=payload,
            timeout=30
        )
        res.raise_for_status()
        
        return res.json().get('response', 'Great job! Keep up the excellent work!')
    except Exception as e:
        logger.error(f"Error generating motivation: {str(e)}")
        return "Great work! Keep pushing yourself to be better every day!"
    

async def generate_workout_times_per_day(user_id: str, user_health_profile: UserHealthProfile) -> dict:
    """Generate AI feedback on workout times per day"""
    try:
        prompt = f"""You are an expert adaptive fitness advisor specializing in personalized exercise planning for diverse health conditions and disabilities.

            Analyze the user's complete health profile thoroughly:
            - Current health conditions and disabilities
            - Physical limitations and mobility restrictions
            - Age, fitness level, and medical history
            - Chronic conditions (heart disease, diabetes, arthritis, etc.)
            - Neurological conditions (MS, Parkinson's, stroke recovery, etc.)
            - Joint problems, chronic pain, or injuries
            - Cardiovascular or respiratory limitations

            CRITICAL DISABILITY ASSESSMENT:
            - If the user has disabilities or conditions that make squats, pushups, or plank UNSAFE or CONTRAINDICATED, set times_per_day to 0
            - For mobility impairments affecting lower body: set squats to 0
            - For upper body limitations, shoulder injuries, or severe arthritis: set pushups and plank to 0
            - For balance disorders or fall risk: set squats to 0
            - For cardiovascular conditions limiting floor exercises: adjust accordingly
            - For wheelchair users or severe mobility restrictions: prioritize adaptive alternatives

            Provide specific, evidence-based recommendations for each exercise:
            - Squats: Consider knee health, lower body mobility, balance, fall risk
            - Pushups: Consider shoulder health, upper body strength, wrist/elbow conditions
            - Plank: Consider core stability, back conditions, shoulder health

            For each workout, specify:
            1. Safe frequency (times_per_day: 0-3) based on their specific conditions
            2. Detailed reasoning explaining WHY this frequency is recommended, addressing their specific health conditions and any disabilities

            Be encouraging but PRIORITIZE SAFETY. Never recommend exercises that could worsen existing conditions or disabilities.

            User Health Profile:
            {user_health_profile.model_dump_json() if hasattr(user_health_profile, 'model_dump_json') else str(user_health_profile)}
            """
        res = requests.post(
            f"{NGROK_URL}/api/generate",
            headers={"Content-Type": "application/json"},
            json={
                "model": "qwen3:8b",
                "prompt": prompt,
                "stream": False,
                "options": {"temperature": 0.7},
                "format": WorkoutSummary.model_json_schema()
            },
            timeout=60
        )
        res.raise_for_status()
        llm_response_json_str = res.json().get('response', '{}')
        return json.loads(llm_response_json_str)
    except Exception as e:
        logger.error(f"Error generating motivation: {str(e)}")
        return {'squats': {'times_per_day': 0, 'reason_for_the_workout_plan': 'No data'},
                'pushups': {'times_per_day': 0, 'reason_for_the_workout_plan': 'No data'},
                'plank': {'times_per_day': 0, 'reason_for_the_workout_plan': 'No data'}}


