from fastapi import FastAPI
from routes.chat_routes import router as chat_router
from routes.agent_routes import router as agent_router
from routes.voice_routes import router as voice_router
from routes.emotion_route import router as emotion_router
from routes.workout_routes import router as workout_router
from core.db import initialize_database
from utils.retriever import check_and_create_vector_store
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    This function runs on application startup and shutdown.
    It's the perfect place to initialize resources like databases.
    """
    # --- Startup ---
    print("\n--- 🚀 KICKING OFF STARTUP PROCEDURES ---")
    initialize_database()
    check_and_create_vector_store()
    print("\n--- ✅ STARTUP COMPLETE. API IS READY TO SERVE. ---")
    yield
    # --- Shutdown ---
    print("\n--- 🌙 SHUTTING DOWN ---")


# Create the FastAPI app instance with the lifespan event handler
app = FastAPI(
    lifespan=lifespan,
    title="BeMA Application API",
    description="API for the Health Monitor Agent and other services.",
    version="1.0.0"
)

app.include_router(chat_router, prefix="/api", tags=["Chat"])
app.include_router(agent_router, prefix="/api", tags=["RAG Agent"])
app.include_router(voice_router, prefix="/api", tags=["Voice"])
app.include_router(emotion_router, prefix="/api", tags=["Emotion"])
app.include_router(workout_router, prefix="/api", tags=["Workout"])

@app.get("/", tags=["Root"])
async def root():
    """A simple endpoint to confirm the API is running."""
    return {"message": "Welcome to the BeMA Application API!"}

