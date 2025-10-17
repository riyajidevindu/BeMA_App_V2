from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class PoseSessionRequest(BaseModel):
    user_id: str
    exercise: str
    reps: int
    accuracy: float
    timestamp: str
    duration: int
    feedback_points: Optional[List[str]] = []


class PoseSessionResponse(BaseModel):
    success: bool
    message: str
    motivational_feedback: Optional[str] = None
