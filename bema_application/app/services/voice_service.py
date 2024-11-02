import os
from groq import Groq
from gtts import gTTS
client = Groq()

async def transcribe_audio():
    filename = os.path.relpath("app/data/voice/sample.mp3")
    with open(filename, "rb") as file:
        transcription = client.audio.transcriptions.create(
         file=(filename, file.read()), 
         model="whisper-large-v3-turbo", 
         prompt="Specify context or spelling",  
         response_format="json",  
         language="en",  
         temperature=0.0 
    )
    return transcription.text

async def text_to_speech(text):
    tts = gTTS(text=text, lang='en')
    output_file = "response.mp3"
    tts.save(output_file)
    return output_file
    