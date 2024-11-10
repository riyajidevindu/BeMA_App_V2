import io
from groq import Groq
from gtts import gTTS
from app.services.chat_service import answer_question

client = Groq()

async def transcribe_audio_data(audio_data):
    try:
        # Create a file-like object from the audio data
        audio_file = io.BytesIO(audio_data)
        
        # Perform the transcription
        transcription = client.audio.transcriptions.create(
            file=("audio.mp3", audio_file),  # Assuming MP3 format, adjust if needed
            model="whisper-large-v3-turbo",
            prompt="Specify context or spelling",
            response_format="json",
            language="en",
            temperature=0.0
        )
        
        return transcription.text
    except Exception as e:
        print(f"Error in transcribe_audio_data: {str(e)}")
        return None

async def text_to_speech(text):
    tts = gTTS(text=text, lang='en')
    output_file = io.BytesIO()
    tts.write_to_fp(output_file)
    output_file.seek(0)
    return output_file.getvalue()
    
async def process_audio_message(audio_data):
    transcribed_text = await transcribe_audio_data(audio_data)
    if transcribed_text:
        response = await answer_question(question=transcribed_text)
        response_text = response["parsed"]["answer"] if response["parsed"] else "Sorry, I couldn't understand that."
        audio_response = await text_to_speech(response_text)
        return audio_response
    else:
        return await text_to_speech("Sorry, I couldn't transcribe the audio.")