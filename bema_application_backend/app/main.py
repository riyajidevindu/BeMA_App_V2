from fastapi import FastAPI
from app.routes.agent import router as agent_router
from app.services.embedding_service import vector_embedding

app = FastAPI()

# Include the agent routes
app.include_router(agent_router)

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