import json
from models.user_health import UserHealthProfile
from fastapi import APIRouter, HTTPException
from models.pose_session import PoseSessionRequest, PoseSessionResponse
from core.db import get_db_connection, DB_CONFIG, get_user_health_profile
from datetime import datetime
import logging
import requests
import os
from dotenv import load_dotenv
from services.workout_service import generate_workout_motivation, generate_workout_times_per_day

load_dotenv()

router = APIRouter()
logger = logging.getLogger(__name__)

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
    
@router.get("/workout/plan/{user_id}", response_model=dict)
async def get_workout_plan(user_id: str):
    """
    Get personalized workout plan for the user
    """
    try:
        user_health_profile =  get_user_health_profile(user_id)
        if not user_health_profile:
            raise HTTPException(status_code=404, detail="User health profile not found")

        workout_plan = await generate_workout_times_per_day(user_id, user_health_profile)
        return {"user_id": user_id, "workout_plan": workout_plan}

    except Exception as e:
        logger.error(f"Error fetching workout plan: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch workout plan: {str(e)}")
