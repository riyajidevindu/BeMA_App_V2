import json
from fastapi import APIRouter, HTTPException
from app.services.voice_service import transcribe_audio_data,text_to_speech
from app.services.chat_service import answer_question

router = APIRouter()


@router.post("/voice/")
async def query_voice():
    try:
        text = await transcribe_audio_data()
        response = await answer_question(question=text)
        if response['parsed']:
            response_text = response["parsed"]["answer"]
            audio_file = await text_to_speech(response_text)

            return {"text": response_text, "audio_file": audio_file}
        else:
            raise HTTPException(status_code=500, detail="Failed to parse response")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
      
