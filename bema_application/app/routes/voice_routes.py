import io
import json
from fastapi import APIRouter, HTTPException, UploadFile, File
from fastapi.responses import StreamingResponse
from services.voice_service import transcribe_audio_data,text_to_speech
from services.chat_service import answer_question_with_memory

router = APIRouter()


@router.post("/voice/")
async def query_voice(audio_file: UploadFile = File(...)):
    try:
        # Read the uploaded audio file
        audio_data = await audio_file.read()
        
        # Transcribe the audio data
        text = await transcribe_audio_data(audio_data)
        if not text:
            raise HTTPException(status_code=400, detail="Failed to transcribe audio")
        
        # Generate a response
        response = answer_question_with_memory(question=text)
        response_text = response if isinstance(response, str) else str(response)
        
        # Convert the response text to speech
        audio_response = await text_to_speech(response_text)
        if not audio_response:
            raise HTTPException(status_code=500, detail="Failed to generate audio response")
        
        # Create a StreamingResponse with the audio data
        audio_stream = io.BytesIO(audio_response)
        
        return StreamingResponse(audio_stream, media_type="audio/mpeg")

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
