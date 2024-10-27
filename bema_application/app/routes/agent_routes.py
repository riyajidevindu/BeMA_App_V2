# app/routes/agent.py
from fastapi import APIRouter, HTTPException
from app.models.user_health import UserHealthProfile
from app.services.agent_service import get_response

router = APIRouter()


@router.post("/agent/")
async def query_agent(user_health_profile: UserHealthProfile):
    try:
        response = get_response(user_health_profile)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
