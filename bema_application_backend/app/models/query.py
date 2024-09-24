from pydantic import BaseModel 
from typing import List

class QueryRequest(BaseModel):
    query: str
    previous_answers: List[str] 

class DailyHealthRecommendations(BaseModel):
    water_intake: str
    walking_duration: str
    stretching_time: str
    mindfulness_exercise: str
    nutrition_tip: str
    sleep_reminder: str
    screen_time_break: str
    daily_challenge: str
    social_interaction: str
    posture_reminder: str

class ResponseTemplate(BaseModel):
    status: bool = True
    message: str = "Data successfully retrieved!"
    status_code: int = 200
    data: DailyHealthRecommendations