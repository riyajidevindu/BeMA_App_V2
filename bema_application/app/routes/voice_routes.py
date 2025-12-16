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
        print(f"📥 Received audio file, size: {len(audio_data)} bytes")
        
        # Transcribe the audio data
        text = await transcribe_audio_data(audio_data)
        if not text:
            raise HTTPException(status_code=400, detail="Failed to transcribe audio")
        print(f"📝 Transcribed text: '{text}'")
        
        # Generate a response
        print("🤖 Generating LLM response...")
        response = answer_question_with_memory(question=text)
        print(f"✅ LLM Response type: {type(response)}")
        print(f"✅ LLM Response: {response}")
        
        # Extract only the "answer" part for TTS
        answer_text = ""
        if isinstance(response, dict):
            answer_text = response.get("answer", "")
            print(f"📖 Extracted answer from dict: '{answer_text}'")
        elif isinstance(response, str):
            try:
                response_dict = json.loads(response)
                answer_text = response_dict.get("answer", response)
                print(f"📖 Extracted answer from JSON string: '{answer_text}'")
            except json.JSONDecodeError as e:
                print(f"⚠️ JSON decode error: {e}, using raw response")
                answer_text = response
        
        if not answer_text:
            print("❌ No answer text found!")
            raise HTTPException(status_code=500, detail="No answer found in response")
        
        # Convert only the answer text to speech
        print(f"🔊 Converting to speech: '{answer_text}'")
        audio_response = await text_to_speech(answer_text)
        if not audio_response:
            raise HTTPException(status_code=500, detail="Failed to generate audio response")
        
        print(f"✅ Audio generated, size: {len(audio_response)} bytes")
        
        # Create a StreamingResponse with the audio data
        audio_stream = io.BytesIO(audio_response)
        
        return StreamingResponse(audio_stream, media_type="audio/mpeg")

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error in query_voice: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
