import json

from requests import request
from fastapi import APIRouter, HTTPException
from services.chat_service import answer_question_with_memory
from pydantic import BaseModel
from models.answer_with_justification import AnswerWithJustification

router = APIRouter()

class QuestionRequest(BaseModel):
    question: str

@router.post("/bot/")
async def query_agent(request: QuestionRequest):
    try:
        response = answer_question_with_memory(question=request.question)
        return response
    except Exception as e:
        print(f"Error in query_agent: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) from e