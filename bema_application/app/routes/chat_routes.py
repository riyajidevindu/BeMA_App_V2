import json
from fastapi import APIRouter, HTTPException
from app.services.chat_service import answer_question
from pydantic import BaseModel

router = APIRouter()

class QuestionRequest(BaseModel):
    question: str

@router.post("/bot/")
async def query_agent(request: QuestionRequest):
    try:
        response = await answer_question(question=request.question)
        # parsed_content = json.loads(response['raw'].content) 
        # answer = parsed_content['answer']
        # justification = parsed_content['justification']

        # return {"answer": answer, "justification": justification}

        return response['parsed']
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e