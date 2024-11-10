from fastapi import FastAPI, WebSocket
from fastapi.websockets import WebSocketDisconnect
from app.routes.chat_routes import router as chat_router
from app.routes.agent_routes import router as agent_router
from app.routes.voice_routes import router as voice_router
from app.services.agent_service import vector_embedding
from app.services.voice_service import process_audio_message
from app.services.chat_service import answer_question

app = FastAPI()

# Include the existing routes
app.include_router(chat_router)
app.include_router(agent_router)
app.include_router(voice_router)

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

# WebSocket endpoint
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            message_type = await websocket.receive_text()
            
            if message_type == "text":
                text = await websocket.receive_text()
                response = await process_text_message(text)
                await websocket.send_text(response)
            
            elif message_type == "audio":
                audio_data = await websocket.receive_bytes()
                response = await process_audio_message(audio_data)
                await websocket.send_bytes(response)
            
            else:
                await websocket.send_text("Invalid message type")
    
    except WebSocketDisconnect:
        print("WebSocket disconnected")

async def process_text_message(text: str):
    response = await answer_question(question=text)
    return response["parsed"]["answer"] if response["parsed"] else "Sorry, I couldn't understand that."