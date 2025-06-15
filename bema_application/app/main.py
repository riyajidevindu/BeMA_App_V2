# import base64
# import json
# import os
from fastapi import FastAPI
from app.routes.chat_routes import router as chat_router
from app.routes.agent_routes import router as agent_router
from app.routes.voice_routes import router as voice_router
from app.routes.emotion_route import router as emotion_router
from app.services.agent_service import vector_embedding



app = FastAPI()

# Include the existing routes
app.include_router(chat_router)
app.include_router(agent_router)
app.include_router(voice_router)
app.include_router(emotion_router)

@app.on_event("startup")
def startup_event():
    """
    Initialize resources when the application starts.
    """
    try:
        vector_embedding()  
        print("Vector database is ready.")
    except Exception as e:
        print(f"Error during startup: {e}")

@app.get("/")
async def root():
    return {"message": "Welcome to the Health Monitor Agent API!"}

# audio_directory = "app/audio_files"
# os.makedirs(audio_directory, exist_ok=True)
# # WebSocket endpoint
# @app.websocket("/ws")
# async def websocket_endpoint(websocket: WebSocket):
#     await websocket.accept()
#     print("WebSocket connection established")
#     try:
#         while True:
#             message = await websocket.receive_text()
#             print(f"Received message: {message[:100]}...")
#             try:
#                 data = json.loads(message)
#                 message_type = data.get("type")
#                 print(f"Received message type: {message_type}")

#                 if message_type == "audio":
#                     print("Received audio signal, waiting for audio data...")
#                     await websocket.send_text(json.dumps({"type": "info", "content": "Ready for audio data"}))
#                 elif message_type == "audio_data":
#                     base64_audio = data.get("content")
#                     if base64_audio:
#                         audio_data = base64.b64decode(base64_audio)
#                         print(f"Received audio data size: {len(audio_data)} bytes")
#                         file_path = os.path.join(audio_directory, "received_audio.wav")
#                         with open(file_path, "wb") as audio_file:
#                             audio_file.write(audio_data)
#                         print(f"Audio data saved to {file_path}")
#                         if len(audio_data) == 0:
#                             print("Error: Received empty audio data")
#                             await websocket.send_text(json.dumps({"type": "error", "content": "Received empty audio data"}))
#                         else:
#                             try:
#                                 response_audio_data = await process_audio_message(audio_data)
#                                 if response_audio_data:
#                                     print(f"Sending audio response, size: {len(response_audio_data)} bytes")
#                                     await websocket.send_bytes(response_audio_data)
#                                 else:
#                                     print("No audio response generated")
#                                     await websocket.send_text(json.dumps({"type": "error", "content": "Failed to generate audio response"}))
#                             except Exception as e:
#                                 print(f"Error processing audio message: {str(e)}")
#                                 await websocket.send_text(json.dumps({"type": "error", "content": f"Error processing audio message: {str(e)}"}))
#                     else:
#                         print("Error: No audio content in message")
#                         await websocket.send_text(json.dumps({"type": "error", "content": "No audio content in message"}))

#                 elif message_type == "text":
#                     text = data.get("content", "")
#                     print(f"Received text message: {text}")
#                     try:
#                         response = await answer_question(question=text)
#                         response_text = response["parsed"]["answer"] if response.get("parsed") else "Sorry, I couldn't understand that."
#                         print(f"Sending text response: {response_text[:100]}...")
#                         await websocket.send_text(json.dumps({"type": "text", "content": response_text}))
#                     except Exception as e:
#                         print(f"Error processing text message: {str(e)}")
#                         await websocket.send_text(json.dumps({"type": "error", "content": f"Error processing text message: {str(e)}"}))

#                 else:
#                     print(f"Invalid message type: {message_type}")
#                     await websocket.send_text(json.dumps({"type": "error", "content": "Invalid message type"}))

#             except json.JSONDecodeError as e:
#                 print(f"Error: Invalid JSON format - {str(e)}")
#                 await websocket.send_text(json.dumps({"type": "error", "content": "Invalid JSON format"}))

#     except WebSocketDisconnect:
#         print("WebSocket disconnected")
#     except Exception as e:
#         print(f"Unexpected error in WebSocket handler: {str(e)}")
#         await websocket.send_text(json.dumps({"type": "error", "content": f"Unexpected error: {str(e)}"}))


# async def process_text_message(text: str):
#     response = await answer_question(question=text)
#     return response["parsed"]["answer"] if response.get("parsed") else "Sorry, I couldn't understand that."