from fastapi import FastAPI
from app.routes.chat_routes import router as chat_router
from app.routes.agent_routes import router as agent_router
from app.services.agent_service import vector_embedding
from app.routes.voice_routes import router as voice_router

app = FastAPI()

# Include the chat routes
app.include_router(chat_router)

# Include the agent routes
app.include_router(agent_router)

# Include the voice routes
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
