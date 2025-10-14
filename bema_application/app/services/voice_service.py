import io
from groq import Groq
from gtts import gTTS
from services.chat_service import answer_question_with_memory

client = Groq()

async def transcribe_audio_data(audio_data):
    print("Starting transcription...")
    try:
        audio_file = io.BytesIO(audio_data)
        print(f"Audio file created, size: {len(audio_data)} bytes")
        
        transcription = client.audio.transcriptions.create(
            file=("audio.mp3", audio_file),
            model="whisper-large-v3-turbo",
            prompt="Specify context or spelling",
            response_format="json",
            language="en",
            temperature=0.0
        )
        
        print(f"Transcription completed: {transcription.text}")
        return transcription.text
    except Exception as e:
        print(f"Error in transcribe_audio_data: {str(e)}")
        return None

async def text_to_speech(text):
    print(f"Converting text to speech: '{text}'")
    try:
        tts = gTTS(text=text, lang='en')
        output_file = io.BytesIO()
        tts.write_to_fp(output_file)
        output_file.seek(0)
        audio_data = output_file.getvalue()
        print(f"Text-to-speech conversion completed, audio size: {len(audio_data)} bytes")
        return audio_data
    except Exception as e:
        print(f"Error in text_to_speech: {str(e)}")
        return None
    
async def process_audio_message(audio_data):
    print("Processing audio message...")
    try:
        transcribed_text = await transcribe_audio_data(audio_data)
        if transcribed_text:
            print(f"Transcribed text: '{transcribed_text}'")
            response = answer_question_with_memory(question=transcribed_text)
            response_text = response if isinstance(response, str) else str(response)
            print(f"Response text: '{response_text}'")
            audio_response = await text_to_speech(response_text)
            if audio_response:
                print(f"Audio response generated, size: {len(audio_response)} bytes")
                return audio_response
            else:
                print("Failed to generate audio response")
        else:
            print("Transcription failed")
        return await text_to_speech("Sorry, I couldn't process your audio.")
    except Exception as e:
        print(f"Error in process_audio_message: {str(e)}")
        return await text_to_speech("Sorry, there was an error processing your audio.")