from fastapi import APIRouter, HTTPException
from models.pose_session import PoseSessionRequest, PoseSessionResponse
from core.db import get_db_connection, DB_CONFIG
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


@router.post("/workout/pose-summary", response_model=PoseSessionResponse)
async def save_pose_session(session: PoseSessionRequest):
    """
    Save workout session data and generate AI motivational feedback
    """
    try:
        connection = get_db_connection(DB_CONFIG)
        cursor = connection.cursor()

        # Insert workout session into database
        insert_query = """
        INSERT INTO workout_sessions 
        (user_id, exercise, reps, accuracy, timestamp, duration, feedback_points)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        
        cursor.execute(insert_query, (
            session.user_id,
            session.exercise,
            session.reps,
            session.accuracy,
            session.timestamp,
            session.duration,
            ','.join(session.feedback_points) if session.feedback_points else ''
        ))
        
        connection.commit()
        session_id = cursor.lastrowid

        # Generate AI motivational feedback
        performance_context = f"""
        User completed {session.reps} {session.exercise} with {session.accuracy:.1f}% accuracy 
        in {session.duration} seconds. 
        Feedback points: {', '.join(session.feedback_points) if session.feedback_points else 'None'}
        """
        
        motivational_feedback = await generate_workout_motivation(
            user_id=session.user_id,
            performance_context=performance_context
        )

        cursor.close()
        connection.close()

        return PoseSessionResponse(
            success=True,
            message=f"Workout session saved successfully with ID: {session_id}",
            motivational_feedback=motivational_feedback
        )

    except Exception as e:
        logger.error(f"Error saving workout session: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to save workout session: {str(e)}")
